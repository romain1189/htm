module HTM
  class Column
    include Enumerable
    include HTM::Logging

    CELL_NUMBER = 20

    # Exponential moving average alpha
    # Number of period N = 1000 where alpha = 2 / (N + 1)
    # Numenta docs specify the period should be over the last 1000 iterations
    EMA_ALPHA = 2.0 / (1000.0 + 1.0)

    attr_reader :overlap, :boost, :active_duty_cycle, :overlap_duty_cycle, :x,
                :y

    attr_accessor :active
    alias_method :active?, :active

    # Find the maximum active duty cycle in the given list of columns.
    #
    # @param [Array<Column>] columns the list of columns
    # @return [Float] the max duty cycle
    def self.max_duty_cycle(columns)
      columns.max { |a, b|
        a.active_duty_cycle <=> b.active_duty_cycle
      }.active_duty_cycle
    end

    def initialize(region, x, y, proximal_synapses_number,
                   cell_number = CELL_NUMBER)

      # The position in the region
      @x = x
      @y = y

      # The last computed input overlap for the Column
      @overlap = 0

      # The boost value as computed during learning. Used to increase the
      # overlap value for inactive columns.
      @boost = 0.0

      # A sliding average representing how often the column has had significant
      # overlap (i.e greater than minOverlap) with its inputs (e.g over the last
      # 1000 iterations).
      @overlap_duty_cycle = 0.0

      # A sliding average representing how often the column has been active
      # after inhibition (e.g over the last 1000 iterations)
      @active_duty_cycle = 0.0

      # Indicates if the column won after the spatial pooling inhibition step
      @active = false

      @proximal_segment = DendriteSegment.new

      region.input_positions.sample(proximal_synapses_number).each do |pt|
        input = InputCell.new(pt.x, pt.y, region)
        permanence = random_permanence(pt.x, pt.y, region)
        @proximal_segment << Synapse.new(input, permanence)
      end

      @cells = Array.new(cell_number) { Cell.new }
    end

    # Gives a change to the column to update his state before a new input is
    # given to the region
    #
    # @return [void]
    def before_tick!
      @cells.each { |cell| cell.before_tick! }
    end

    # Compute the overlap with the current input
    #
    # @param [Integer] min_overlap the minimum overlap
    # @return [Integer] the new overlap
    def compute_overlap(min_overlap)
      count = @proximal_segment.each_connected.count { |synapse|
        synapse.active?(:active)
      }

      @overlap = if count < min_overlap
        0
      else
        count.to_f * @boost
      end
    end

    # Computes a moving average of how often the column has been active after
    # inhibition.
    #
    # @return [Float] the new active moving average
    def update_active_duty_cycle
      value = @active ? 1.0 : 0.0
      @active_duty_cycle += EMA_ALPHA * (value - @active_duty_cycle)
    end

    # Computes a moving average of how often column c has overlap greater than
    # min_overlap.
    #
    # @param [Numeric] min_overlap the minimum overlap value
    # @return [Float] the new overlap moving average
    def update_overlap_duty_cycle(min_overlap)
      value = @overlap > min_overlap ? 1.0 : 0.0
      @overlap_duty_cycle += EMA_ALPHA * (value - @overlap_duty_cycle)
    end

    # Update synapse permanence and internal variables
    #
    # @param [Array<Column>] neighbors the list of neighbors columns
    # @param [Integer] min_overlap the minimum overlap
    # @return [void]
    def learn(neighbors, min_overlap)
      min_duty_cycle = 0.01 * Column.max_duty_cycle(neighbors)
      update_active_duty_cycle

      perform_boost(min_duty_cycle)

      update_overlap_duty_cycle(min_overlap)
      if @overlap_duty_cycle < min_duty_cycle
        increase_permanences(0.1 * Synapse.threshold)
      end
    end

    # Increase the permanence value of every synapse in column by a scale factor
    #
    # @param [Float] scale_factor a scale factor
    # @return [void]
    def increase_permanences(scale_factor)
      @proximal_segment.each do |synapse|
        synapse.increase_permanence(scale_factor)
      end
    end

    # Calls <i>block</i> once for each cell in <b>self</b>, passing that element
    # as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam [Cell] cell the cell that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Cell>]
    def each
      if block_given?
        @cells.each { |cell| yield(cell) }
        nil
      else
        @cells.each
      end
    end
    alias_method :each_cell, :each

    # Calls <i>block</i> once for each connected synapses in <b>self</b>
    # proximal segment, passing that element as a parameter
    #
    # @yieldparam [Synapse] synapse the connected synapse that is yielded
    # @return nil
    def each_connected_synapses
      @proximal_segment.each_connected_synapses { |synapse| yield(synapse) }
      nil
    end

    # Return the cell with the best matching segment (as defined in
    # {Cell#best_matching_segment}). If no cell has a matching segment, then
    # return the cell with the fewest number of segments.
    #
    # @return [Array<Cell, Segment>]
    def best_matching_cell
      segment = nil
      best = @cells.max_by { |cell|
        segment = cell.best_matching_segment
        segment.nil? ? 0 : segment.activity(:active)
      }

      best = @cells.min { |a, b| a.count <=> b.count } if best.nil?

      [cell, segment]
    end

    # Return the previous cell with the best matching segment (as defined in
    # {Cell#best_matching_segment}). If no cell has a matching segment, then
    # return the cell with the fewest number of segments.
    #
    # @return (see #best_matching_cell)
    def best_previous_matching_cell
      segment = nil
      best = @cells.max_by { |cell|
        segment = cell.best_previous_matching_segment
        segment.nil? ? 0 : segment.previous_activity(:active)
      }

      best = @cells.min { |a, b| a.count <=> b.count } if best.nil?

      [cell, segment]
    end

    private

    # Updates the boost value of a column. The boost value is a scalar >= 1. If
    # active_duty_cycle is above min_duty_cycle, the boost value is 1. The boost
    # increases linearly once the column's active_duty_cycle starts falling
    # below its min_duty_cycle.
    #
    # @param [Float] min the min duty cycle
    # @return [Float] the new boost value
    def perform_boost(min)
      if @active_duty_cycle > min
        @boost = 1.0
      else
        @boost *= 1.05
      end
    end

    # The random permanence values are chosen with two criteria. First, the
    # values are chosen to be in a small range around {Synapse.threshold} (the
    # minimum permanence value at which a synapse is considered "connected").
    # This enables potential synapses to become connected (or disconnected)
    # after a small number of training iterations. Second, each column has a
    # natural center over the input region, and the permanence values have a
    # bias towards this center (they have higher values near the center).
    #
    # @todo check!
    # @return [Float]
    def random_permanence(x, y, region)
      # First criteria
      permanence = Synapse.threshold + Synapse.incrementation_value * rand

      # Second criteria
      cx = (@x * region.cell_width_in_input_space).round
      cy = (@y * region.cell_height_in_input_space).round

      distance = Math.sqrt((cx - x) ** 2 + (cy - y) ** 2)

      longer_side = [region.input_width, region.input_height].max
      exponent = distance / (longer_side * 0.25)
      bias = (0.8 / 0.4) * Math.exp((exponent ** 2) / -2)

      #debug "perm calc of (#{x}, #{y}): d=#{distance}, cx=#{cx} cy=#{cy} \
      #       ex:#{exponent}, bias:#{bias}"

      permanence * bias
    end
  end
end
