module HTM
  class Cell
    include Enumerable

    attr_accessor :active, :predictive, :learning
    attr_reader :was_active, :was_predictive, :was_learning

    def initialize

      # We maintain three different states for the cell:
      #
      # * active (via proximal dendrite, e.g feed-forward input)
      # * predictive (via distal dendrite, e.g lateral input)
      # * learning
      #
      # The learn state determines which cell outputs are used during learning.
      # When an input is unexpected, all the cells in a particular column become
      # active in the same time step. Only one of those cells (the cell that
      # best matches the input) has its learn state turned on. We only add
      # synapses from cells that have learn state set to true (this avoids
      # overrepresenting a fully active column in dendritic segments).
      @states = {
        active: [false, false],
        predictive: [false, false],
        learning: [false, false]
      }

      @distal_segments = []
      @segment_updates = []
    end

    %w(active predictive learning).each do |state|
      symbol = state.to_sym

      define_method(symbol) { @states[symbol][-1] }
      alias_method "#{state}?".to_sym, symbol
      define_method("#{state}=".to_sym) { |v| @states[symbol][-1] = v }

      define_method("was_#{state}".to_sym) { @states[symbol][-2] }
      alias_method("was_#{state}?".to_sym, "was_#{state}".to_sym)
    end

    # Gives a change to the cell to update his state before a new input is
    # given to the region
    #
    # @return [void]
    def before_tick!
      @states[:active].push(false).shift
      @states[:predictive].push(false).shift
      @states[:learning].push(false).shift

      @distal_segments.each { |segment| segment.before_tick! }
    end

    # Create a new dendrite segment that will be connected to the given cells
    #
    # @param [Array<Cell>] cells the cells to connect the segment to
    # @return [Segment] the newly created segment
    def <<(cells)
      segment = DendriteSegment.new
      cells.each { |cell| segment << Synapse.new(cell) }

      @distal_segments << segment
      segment
    end

    # Calls <i>block</i> once for each distal segment in <b>self</b>, passing
    # that element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam [DendriteSegment] segment the segment that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<DendriteSegment>]
    def each
      if block_given?
        @distal_segments.each { |segment| yield(segment) }
        nil
      else
        @distal_segments.each
      end
    end
    alias_method :each_segment, :each
    alias_method :each_distal_segment, :each

    # Find the segment with the largest number of active synapses. This method
    # is aggressive in finding the best match. The permanence value of synapses
    # is allowed to be below {Synapse.threshold}. The number of
    # active synapses is allowed to be below
    # {DendriteSegment#activation_threshold}, but must be above
    # {DendriteSegment#min_threshold}.
    # The method returns the segment. If no segments are found, <b>nil</b> is
    # returned.
    #
    # @return [DendriteSegment] the best matching segment
    def best_matching_segment
      @distal_segments.sort { |a, b|
        a.activity(:active) <=> b.activity(:active)
      }.select { |segment| segment.aggressively_active?(:active) }.first
    end

    # Find the previous segment with the largest number of active synapses.
    # This method is aggressive in finding the best match. The permanence value
    # of synapses is allowed to be below {Synapse.threshold}. The number of
    # active synapses is allowed to be below
    # {DendriteSegment#activation_threshold}, but must be above
    # {DendriteSegment#min_threshold}.
    # The method returns the segment. If no segments are found, <b>nil</b> is
    # returned.
    #
    # @return (see #best_matching_segment)
    def best_previous_matching_segment
      @distal_segments.sort { |a, b|
        a.previous_activity(:active) <=> b.previous_activity(:active)
      }.select { |segment| segment.was_aggressively_active?(:active) }.first
    end

    # Return a segment such that {DendriteSegment#active?} is <b>true</b>. If
    # multiple segment are active, sequence segments are given preference.
    # Otherwise, segments with most activity are given preference.
    #
    # @param [Symbol] state the state, either <b>:active</b> or <b>:learning</b>
    # @return [DendriteSegment] the preferred active segment or nil
    def active_segment(state)
      segments = @distal_segments.select { |segment| segment.active?(state) }

      return segments.first if segments.count == 1
      return nil if segments.empty?

      segments = segments.select(&:sequence?)
      return segments.first if segments.count == 1

      segments.max { |a, b| a.activity(state) <=> b.activity(state) }
    end

    # Return a previous segment such that {DendriteSegment#active?} is
    # <b>true</b>. If multiple segment are active, sequence segments are given
    # preference. Otherwise, segments with most activity are given preference.
    #
    # @param (see #active_segment)
    # @return (see #active_segment)
    def previous_active_segment(state)
      segments = @distal_segments.select { |segment|
        segment.was_active?(state)
      }

      return segments.first if segments.count == 1
      return nil if segments.empty?

      segments = segments.select(&:sequence?)
      return segments.first if segments.count == 1

      segments.max { |a, b|
        a.previous_activity(state) <=> b.previous_activity(state)
      }
    end

    # Build a {DendriteSegment::UpdateInfo} object, which represent proposed
    # changes to the given segment, then push this object to the segment updates
    # list of the cell.
    #
    # @param [Region] region
    # @param [Column] column
    # @param [DendriteSegment] segment
    # @param [Hash] opts the options to build a segment update with
    # @option opts [Boolean] :new_synapses (false)
    # @option opts [Boolean] :previous_time_step (false) flag indicating which
    #   time step is used to build the segment update
    # @option opts [Boolean] :sequence (false)
    # @return [nil]
    def build_segment_update(region, column, segment, opts = {})
      opts = {
        new_synapses: false,
        previous_time_step: false,
        sequence: false
      }.merge(opts)

      synapses = if segment.nil?
        []
      elsif opts[:previous_time_step]
        segment.previous_active_connected_synapses
      else
        segment.active_connected_synapses
      end

      learn_cells = []

      # Let activeSynapses be the list of active synapses where the originating
      # cells have their activeState output = 1 at time step t. (This list is
      # empty if s = -1 since the segment doesn't exist.) newSynapses is an
      # optional argument that defaults to false. If newSynapses is true, then
      # newSynapseCount - count(activeSynapses) synapses are added to
      # activeSynapses. These synapses are randomly chosen from the set of cells
      # that have learnState output = 1 at time step t.


      # if add_synapses is true, then {#DendriteSegment.new_synapse_count} minus
      # the count of active synapses are added to active synapses. These
      # synapses are randomly chosen from the set of cells that are in a
      # learning state
      if opts[:new_synapses]
        unless segment.nil?
          count = DendriteSegment.new_synapse_count - synapses.count
          count = 0 if count < 0
          if count > 0
            segment_cells = segment.map { |synapse| synapse.input }

            region.each do |col|
              next if col == column
              col.each do |cell|
                unless segment_cells.include?(cell)
                  if (opts[:previous_time_step] && cell.was_learning?) ||
                     (!opts[:previous_time_step] && cell.learning?)
                    learn_cells << cell
                  end
                end
              end
            end

            count = [count, learn_cells.count].min
            learn_cells = learn_cells.sample(count)
          end
        end
      end

      update_info = DendriteSegment::UpdateInfo.new(segment, synapses,
                                                    learn_cells,
                                                    opts[:sequence])
      @segment_updates << update_info
      nil
    end

    # Iterates through <b>@segment_updates</b> and reinforces each segment.
    # For each {DendriteSegment::UpdateInfo} element, the following changes are
    # performed:
    # * If the given flag is <b>true</b> then synapses on the active
    #   list get their permanence counts incremented. All other synapses get their
    #   permanence counts decremented.
    # * If the flag is <b>false</b>, then synapses on the active list get their
    #   permanence counts decremented.
    # * After this step, any synapses in <b>@segment_updates</b> that do yet
    #   exist get added with a initial permanence count.
    #
    # @param [Boolean] positive_reinforcement the flag conditioning synapses
    #   permanence values to be either incremented or decremented
    # @return [nil]
    # @todo
    def adapt_segments(positive_reinforcement)
      @segment_updates.each do |update_info|
        segment = update_info.segment
        active_synapses = update_info.active_synapses

        unless segment.nil?
          segment.each do |synapse|
            if positive_reinforcement
              if active_synapses.include?(synapse)
                synapse.increase_permanence
              else
                synapse.decrease_permanence
              end
            else
              synapse.decrease_permanence if active_synapses.include?(synapse)
            end
          end
        end

        unless update_info.cells.empty?
          if segment.nil?
            new_segment = self << update_info.cells
            new_segment.sequence = update_info.sequence?
          else
            update_info.cells.each { |cell|
              segment << Synapse.new(cell)
            }
            segment.sequence = update_info.sequence?
          end
        end
      end

      # TODO SEQUENCE

      @segment_updates.clear
      nil
    end

  #   void applySegmentUpdates(boolean positiveReinforcement) {
  #   for(SegmentUpdateInfo segInfo : _segmentUpdates) {
  #     Segment segment = segInfo.getSegment();

  #     if(segment!=null) {
  #       if(positiveReinforcement)
  #         segment.updatePermanences(segInfo.getActiveSynapses());
  #       else
  #         segment.decreasePermanences(segInfo.getActiveSynapses());
  #     }

  #     //add new synapses (and new segment if necessary)
  #     if(segInfo.getAddNewSynapses() && positiveReinforcement) {
  #       if(segment==null) {
  #         if(segInfo.numLearningCells() > 0)//only add if learning cells available
  #           segment = segInfo.createCellSegment();
  #       }
  #       else if(segInfo.numLearningCells() > 0) {
  #         //add new synapses to existing segment
  #         segInfo.createSynapsesToLearningCells();
  #       }
  #     }
  #   }

  #   //delete segment update instances after they are applied
  #   _segmentUpdates.clear();
  # }
  end
end
