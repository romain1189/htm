module HTM

  # The output of the region is a vector representing the state of all the cells
  # This vector becomes the input to the next region of the hierarchy if there
  # is one.
  class Region
    include Enumerable
    include HTM::Logging

    attr_accessor :temporal_learning, :spatial_learning
    attr_reader :min_overlap, :input, :previous_input, :input_height,
                :input_width, :width, :height

    alias_method :current_input, :input

    # Prior to receiving any inputs, the region is initialized by computing a
    # list of initial potential synapses for each column. This consists of a
    # random set of inputs selected from the input space. Each input is
    # represented by a synapse and assigned a random permanence value. The
    # random permanence values are chosen with two criteria:
    #
    # 1. the values are chosen to be in a small range around
    #    {Synapse.threshold} (the minimum permanence value at
    #    which a synapse is considered "connected"). This enables potential
    #    synapses to become connected (or disconnected) after a small number
    #    of training iterations.
    # 2. each column has a natural center over the input region, and the
    #    permanence values have a bias towards this center (they have higher
    #    values near the center).
    #
    # @param [Hash] options the options to create a region with.
    # @option options [Integer] :column_height (32) number of rows for region's
    #   columns
    # @option options [Integer] :column_width (32) number of columns for
    #   region's columns
    # @option options [Integer] :input_height (64) number of rows to expect for
    #   input bits array.
    # @option options [Integer] :input_width (64) number of columns to expect
    #   for input bits array.
    # @option options [Float] :min_overlap (0.1) the minimum percent of inputs
    #   that must be active for a column to be considered during the inhibition
    #   step
    # @option options [Float] :synapses_per_segment (0.2) the percentage of
    #   potential synapses connected to feed-forward input for a proximal
    #   segment
    # @option options [Float] :desired_local_activity (0.3) the percentage
    #   controlling the number of columns that will be winners after the
    #   inhibition step
    # @option options [Integer] :cell_per_column_number (10) the number of cells
    #   per column
    # @option options [Float] :segment_activation_threshold (15) the minimum
    #   number of synapses that must be connected for a segment to be
    #   considered active
    # @option options [Float] :segment_min_threshold (1) the minimum number of
    #   synapses that must be connected for a segment to be considered active
    #   in case of an aggressive lookup
    # @option options [Float] :new_synapse_count (5) the maximum number of
    #   synapses added to a distal segment during temporal learning
    # @option options [Float] :synapse_permanence_threshold (0.2) a synapse is
    #   considered connected when its permanence value is above this threshold
    # @option options [Float] :synapse_permanence_increment (0.015) the scalar
    #   value that represent the amount by which a synapse permanence is
    #   incremented
    # @option options [Float] :synapse_permanence_decrement (0.005) the scalar
    #   value that represent the amount by which a synapse permanence is
    #   decremented
    # @option options [Float] synapse_initial_permanence (0.3) the initial
    #   permanence value for a synapse
    # @option options [Boolean] :spatial_learning (true) a flag to enable or
    #   disable spatial learning
    # @option options [Boolean] :temporal_learning (true) a flag to enable or
    #   disable temporal learning
    def initialize(options = {})
      options = {
        column_height: 32,
        column_width: 32,
        input_height: 64,
        input_width: 64,
        min_overlap: 0.1,
        synapses_per_segment: 0.15,
        desired_local_activity: 0.3,
        cell_per_column_number: Column::CELL_NUMBER,
        segment_activation_threshold: DendriteSegment::ACTIVATION_THRESHOLD,
        segment_min_threshold: DendriteSegment::MIN_THRESHOLD,
        new_synapse_count: DendriteSegment::NEW_SYNAPSE_COUNT,
        synapse_permanence_threshold: Synapse::PERMANENCE_THRESHOLD,
        synapse_permanence_increment: Synapse::PERMANENCE_INCREMENT,
        synapse_permanence_decrement: Synapse::PERMANENCE_DECREMENT,
        synapse_initial_permanence: Synapse::INITIAL_PERMANENCE,
        spatial_learning: true,
        temporal_learning: true
      }.merge(options)

      DendriteSegment.activation_threshold =
        options[:segment_activation_threshold]
      DendriteSegment.min_threshold = options[:segment_min_threshold]

      DendriteSegment.new_synapse_count =
        options[:new_synapse_count]

      Synapse.threshold = options[:synapse_permanence_threshold]
      Synapse.incrementation_value = options[:synapse_permanence_increment]
      Synapse.decrementation_value = options[:synapse_permanence_decrement]

      @height = options[:column_height]
      @width = options[:column_width]

      @input_height = options[:input_height]
      @input_width = options[:input_width]

      info "Initializing region of #{@width}x#{@height}..."

      # the number of input bits that a column has potential connections to
      # should at least equals the product between the horizontal and vertical
      # space of the input size to cover all bits.
      min_synapses = (cell_width_in_input_space * cell_height_in_input_space)
                     .ceil
      debug "minimum synapses per segment: #{min_synapses}"

      unless options[:synapses_per_segment].between?(0, 1)
        options[:synapses_per_segment] = 0.2
      end
      synapses_per_segment = [
        min_synapses, input_size * options[:synapses_per_segment]
      ].max.round
      debug "synapses_per_segment: #{synapses_per_segment}"

      # A minimum number of inputs that must be active for a column to be
      # considered during the spatial pooling inhibition step.
      #
      # There's no suggested value for this parameter on Numenta docs
      options[:min_overlap] = 0.1 unless options[:min_overlap].between?(0, 1)
      @min_overlap = (synapses_per_segment * options[:min_overlap]).ceil
      debug "minimum overlap: #{@min_overlap}"

      cell_number = options[:cell_per_column_number]

      @columns = Array.new(size)
      (0...size).each do |i|
        #debug "building column #{i}... thread: #{Thread.current}"
        y = i / @height
        x = i - (y * @height)

        self[x, y] = Column.new(self, x, y, synapses_per_segment, cell_number)
      end

      #debug "back to region... thread: #{Thread.current}"

      # Average connected receptive field size of the columns
      @inhibition_radius = average_receptive_field_size
      debug "inhibition radius: #{@inhibition_radius}"

      # A parameter controlling the number of columns that will be winners after
      # the inhibition step
      unless options[:desired_local_activity].between?(0, 1)
        options[:desired_local_activity] = 0.3
      end
      @desired_local_activity = (@inhibition_radius *
                                options[:desired_local_activity]).round
      debug "desired local activity: #{@desired_local_activity}"

      @spatial_learning = options[:spatial_learning]
      @temporal_learning = options[:temporal_learning]

      info "  spatial learning activated? #{@spatial_learning}"
      info "  temporal learning activated? #{@temporal_learning}"
      info "Done!"
    end

    # Calls <i>block</i> once for each column in <b>self</b>, passing that
    # element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam [Column] column the column that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Column>]
    def each
      if block_given?
        @columns.each { |column| yield(column) }
      else
        @columns.each
      end
    end
    alias_method :each_column, :each

    # Calls <i>block</i> once for each synapse in <b>self</b>, passing that
    # element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam [Synapse] synapse the synapse that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Synapse>]

    # Returns an array of all input positions
    #
    # @return [Array<Array<Integer>>]
    def input_positions
      @input_positions ||= (0...@input_width).map { |x|
        (0...@input_height).map { |y|
          Geometry::Point.new(x, y)
        }
      }.flatten
    end

    # Returns the width of a unique column in the input grid space
    #
    # @return [Float]
    def cell_width_in_input_space
      @input_width.to_f / @width.to_f
    end

    # Returns the height of a unique column in the input grid space
    #
    # @return [Float]
    def cell_height_in_input_space
      @input_height.to_f / @height.to_f
    end

    # Returns the grid size of the region (total number of columns).
    #
    # @return [Integer]
    def size
      @width * @height
    end

    # Returns the grid size of the input bits
    #
    # @return [Integer]
    def input_size
      @input_width * @input_height
    end

    # Performs an iteration
    #
    # @param [Array<Fixnum>] input an array of input bits. The size should
    #   respect the input grid size given at {#initialize} with a row-major
    #   order
    # @return [Array<Fixnum>] the output of the region, a binary array
    #   representing the union of all the active and predicted cells
    def tick(input)
      @columns.each { |column| column.before_tick! }

      @input = input
      @previous_input = @current_input

      active_columns = perform_spatial_pooling
      puts "active_columns: #{active_columns.size}" if active_columns.size > 0
      #perform_temporal_pooling(active_columns)

      output
    end

    # Returns the output of the region for the current state.
    #
    # @returns [Array<Fixnum>] a binary array representing the union of all the
    #   active and predicted cells
    # @todo arrange as serial 3d array (row-major then column-major order) ?
    def output
      ary = Array.new
      byte = 0b0
      i = 0

      c = 0
      @columns.each { |column|
        column.each { |cell|
          c += 1 if cell.active? || cell.predictive?

          byte |= (1 << i % 8) if cell.active? || cell.predictive?

          i += 1
          if (i % 8).zero?
            ary << byte
            byte = 0b0
          end
        }
      }
      puts "count: #{c}" if c > 0
      ary
    end

    # Spatial Pooling
    #
    # The input to this code is an array of bottom-up binary inputs from sensory
    # data of the previous level. The code computes active_columns - the list of
    # columns that win due to the bottom-up input at time t. This list is then
    # sent as input to the temporal pooler routine, i.e active_columns is the
    # output of the spatial pooling routine.
    #
    # The code is split into three distinct phases that occur in sequence:
    #
    # 1. compute the overlap with the current input for each column
    # 2. compute the winning columns after inhibition
    # 3. update synapse permanence and internal variables
    #
    # Although spatial pooler learning is inherently online, you can turn off
    # learning by skypping third phase.
    #
    # @return [Array<Column>] the list of active columns
    def perform_spatial_pooling
      compute_overlap
      active_columns = inhibit
      spatial_learn(active_columns) if @spatial_learning

      active_columns
    end

    # Compute the overlap with the current input for each column. The overlap
    # for each column is simply the number of connected synapses with active
    # inputs, multiplied by its boost. If this value is below min_overlap, we
    # set the overlap score to zero.
    #
    # @return [nil]
    def compute_overlap
      @columns.each { |column| column.compute_overlap(@min_overlap) }
      nil
    end

    # Calculates which columns remain as winners after the inhibition step.
    # desired_local_activity controls the number of columns that end up wining.
    # For example, if desired_local_activity is 10, a column will be a winner if
    # its overlap score is greater than the score of the 10'th highest column
    # within its inhibition radius.
    #
    # @return [Array<Column>] the list of winning columns
    def inhibit
      active_columns = []
      @columns.each do |c|
        c.active = false
        min_local_activity = kth_score(neighbors(c), @desired_local_activity)
        if c.overlap > 0 && c.overlap >= min_local_activity
          active_columns << c
          c.active = true
        end
      end
      active_columns
    end

    # Update synapse permanence and internal variables. Performs learning, it
    # updates the permanence values of all synapses as necessary, as well as the
    # boost and inhibition radius.
    #
    # For winning columns, if a synapse is active, its permanence value is
    # incremented, otherwise it is decremented. Permanence values are
    # constrained to be between 0 and 1.
    #
    # There are two separate boosting mechanisms in place to help a column learn
    # connections. If a column does not win often enough (as measured by
    # {Column#active_duty_cycle}), its overall boost value is increased.
    # Alternatively, if a column's connected synapses do not overlap well with
    # any inputs often enough (as measured by {Column#overlap_duty_cycle}), its
    # permanence values are boosted.
    #
    # Finally, the inhibition radius is recomputed.
    #
    # @note This step can be skipped to turn off spatial learning
    # @note Once learning is turned off, {Column#boost} is frozen
    #
    # @param [Array<Column>] active_columns the list of winning columns
    # @return [nil]
    def spatial_learn(active_columns)
      active_columns.each do |column|
        column.each_potential_synapses { |synapse| synapse.update_permanence }
      end

      @columns.each do |column|
        column.learn(neighbors(column), @min_overlap)
      end

      @inhibition_radius = average_receptive_field_size
      nil
    end

    # Temporal pooling
    #
    # The input to this code is active_columns, as computed by the spatial
    # pooler. The code computes the active and predictive state for each cell at
    # the current timestep. The boolean OR of the active and predictive states
    # for each cell forms the output of the temporal pooler for the next level.
    #
    # The code is split into three distinct phases that occur in sequence:
    #
    # 1. compute the active state for each cell
    # 2. compute the predicted state for each cell
    # 3. update synapses
    #
    # Third phase is only required for learning. However, unlike spatial
    # pooling, first and second phases contain some learning-specific operations
    # when learning is turned on.
    #
    # @param [Array<Column>] active_columns the list of active columns computed
    #   during spatial pooling step
    # @return [void]
    def perform_temporal_pooling(active_columns)
      compute_active_state(active_columns)
      compute_predictive_state
      temporal_learn
    end

    # Compute the active state for each cell in active columns. For each winning
    # column, we determine which cells should become active. If the bottom-up
    # input was predicted by any cell (i.e was in predictive state due to a
    # sequence segment in the previous time step), then those cells become
    # active. If the bottom-up input was unexpected (i.e no cells had a
    # predictive state), then each cell in the column becomes active.
    #
    # @param [Array<Column>] active_columns the list of active columns
    # @return [nil]
    def compute_active_state(active_columns)
      active_columns.each do |column|
        predicted = false
        chosen = false

        column.each do |cell|
          if cell.was_predictive?
            segment = cell.active_segment(:active)
            if segment.sequence?
              predicted = true
              cell.active = true
              if segment.was_active?(:learning)
                chosen = true
                cell.learning = true
              end if @temporal_learning
            end
          end
        end

        column.each { |cell| cell.active = true } unless predicted

        unless chosen
          cell, segment = column.best_previous_matching_cell
          cell.learning = true

          cell.build_segment_update(self, column, segment, new_synapses: true,
                                    previous_time_step: true, sequence: true)
        end if @temporal_learning
      end
    end

    # Calcultes the predictive state for each cell. A cell will turn on its
    # predictive state if any one of its segments become active, i.e if enough
    # of its horizontal connections are currently firing due to feed-forward
    # input. In this case, the cell queues up the following changes:
    #
    # 1. Reinforcement of the currently active segment
    # 2. Reinforcement of a segment that could have predicted this activation,
    #    i.e a segment that has a (potentially weak) match to activity during
    #    the previous time step
    #
    # @return [nil]
    def compute_predictive_state
      @columns.each do |column|
        column.each do |cell|
          cell.each do |segment|
            if segment.active?(:active)
              cell.predictive = true

              cell.build_segment_update(self, column, segment)

              predicted_segment = cell.best_previous_matching_segment

              opts = { new_synapses: true, previous_time_step: true }
              cell.build_segment_update(self, column, predicted_segment, opts)
            end
          end
        end
      end
      nil
    end

    # In this phase segment updates that have been queued up are actually
    # implemented once we get feed-forward input and the cell is chosen as a
    # learning cell. Otherwise, if the cell ever stops predicting for any
    # reason, we negatively reinforce the segments.
    #
    # @return [nil]
    def temporal_learn
      @columns.each do |column|
        column.each do |cell|
          if cell.learning?
            cell.adapt_segments(true)
          elsif !cell.predictive? && cell.was_predictive?
            cell.adapt_segments(false)
          end
        end
      end
      nil
    end

    private

    # Column reference
    #
    # @overload [](i)
    #   @param [Integer] index the column index
    # @overload [](x, y)
    #   @param [Integer] x the column index of the column
    #   @param [Integer] y the row index of the column
    # @return [Column] the matching column or nil if out of range
    def [](*args)
      case args.count
      when 1 then
        @columns[args.first]
      when 2 then
        x, y = *args
        @columns[y * @height + x]
      else
        nil
      end
    end

    # Column assignment
    #
    # @overload [](i, column)
    #   @param [Integer] index the column index
    # @overload [](x, y, column)
    #   @param [Integer] x the column index of the column
    #   @param [Integer] y the row index of the column
    # @param [Column] column the column to replace
    # @return [Column] the assigned column or nil if out of range
    def []=(*args, column)
      case args.count
      when 1 then
        @columns[args.first] = column
      when 2 then
        x, y = *args
        @columns[y * @height + x] = column
      else
        nil
      end
    end

    # Given the list of columns, find the k'th highest overlap value
    #
    # @param [Array<Column>] columns a list of columns
    # @return [Numeric] the k'th highest overlap value
    def kth_score(columns, k)
      overlaps = columns.map { |column| column.overlap }.uniq
      overlaps[[0, overlaps.count - k].max]
    end

    # The radius of the average connected receptive field size of all the
    # columns. The connected receptive field size of a column includes only the
    # connected synapses (those with permanence values >= permanence threshold).
    # This is used to determine the extent of lateral inhibition between
    # columns.
    #
    # @return [Float]
    # @todo check!
    def average_receptive_field_size
      sum = 0.0
      count = 0

      @columns.each do |column|
        column.each_connected_synapses do |synapse|
          x = (column.x * cell_width_in_input_space).round - synapse.input_x
          y = (column.y * cell_height_in_input_space).round - synapse.input_y

          distance = Math.sqrt(x ** 2 + y ** 2)

          sum += distance / cell_width_in_input_space
          count += 1
        end
      end

      sum / count.to_f
    end

    # Build a list of all the columns that are within inhibition radius of the
    # given column
    #
    # @param [Column] column the column
    # @return [Array<Column>]
    def neighbors(column)
      neighbors = []

      radius = @inhibition_radius.round
      radius = 1 if radius.zero?
      start_point = Geometry::Point.new([0, column.x - radius].max,
                                        [0, column.y - radius].max)
      end_point = Geometry::Point.new([@width - 1, column.x + radius].min,
                                      [@height - 1, column.y + radius].min)

      start_point.through(end_point) { |x, y|
        neighbors << self[x, y]
      }

      neighbors
    end
    alias_method :neighbours, :neighbors
  end
end
