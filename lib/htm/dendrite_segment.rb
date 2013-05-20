module HTM
  class DendriteSegment
    include Enumerable

    # the minimum number of synapses that must be connected for a segment to be
    # considered active
    #
    # a typical threshold for a dendrite segment is 15. If 15 valid synapses on
    # a segment are active at once, the dendrite becomes active. There might be
    # hundreds or thousands of cells active nearby, but connecting to only 15 is
    # sufficient to recognize the larger pattern
    # @todo see if should be represented as percentage
    ACTIVATION_THRESHOLD = 15

    MIN_THRESHOLD = 1

    NEW_SYNAPSE_COUNT = 5

    attr_reader :previous_connected_synapses
    attr_accessor :sequence

    alias_method :sequence?, :sequence

    @activation_threshold = ACTIVATION_THRESHOLD
    @min_threshold = MIN_THRESHOLD
    @new_syn_count = NEW_SYNAPSE_COUNT

    class << self
      attr_accessor :activation_threshold, :min_threshold, :new_synapse_count

      def activation_threshold=(value)
        @activation_threshold = [value, @min_threshold].max
      end

      def min_threshold=(value)
        @min_threshold = [value, @activation_threshold].min
      end
    end

    # Data structure holding three pieces of information required to update a
    # given segment:
    #
    # * segment (nil if it's a new segment)
    # * a list of existing synapses
    # * a flag indicating whether this segment should be marked as a sequence
    #   segment (defaults to false)
    class UpdateInfo < Struct.new(:segment, :active_synapses, :cells, :sequence)
      alias_method :sequence?, :sequence
    end

    def initialize
      @synapses = []
      @previous_connected_synapses = []

      # A boolean flag indicating whether the segment predicts feed-forward
      # input on the next time step.
      @sequence = false
    end

    # Gives a change to the segment to update his state before a new input is
    # given to the region
    #
    # @return [void]
    def before_tick!
      @previous_connected_synapses = each_connected.to_a
      @synapses.each { |synapse| synapse.before_tick! }
    end

    # Push the given synapse to the list of synapses.
    #
    # @param [Synapse] synapse the synapse to append
    # @return [self] Returns itself, enabling method chaining
    def <<(synapse)
      @synapses << synapse
      self
    end

    # Calls <i>block</i> once for each synapse in <b>self</b>, passing that
    # element as a parameter.
    #
    # If no block is given, an {Enumerator} is returned instead.
    # @overload each
    #   @yieldparam [Synapse] synapse the synapse that is yielded
    #   @return [nil]
    # @overload each
    #   @return [Enumerator<Synapse>]
    def each
      if block_given?
        @synapses.each { |synapse| yield(synapse) }
      else
        @synapses.each
      end
    end
    alias_method :each_synapses, :each
    alias_method :each_potential_synapses, :each

    # Calls <i>block</i> once for each connected synapse in <b>self</b>,
    # passing that element as a parameter. A subset of {#each} where the
    # permanence value is greater than {Synapse#threshold}
    #
    # If no block is given, an {Enumerator} is returned instead.
    #
    # @overload each_connected_synapses
    #   @yieldparam [Synapse] synapse the connected synapse that is yielded
    #   @return [nil]
    # @overload each_connected_synapses
    #   @return [Enumerator<Synapse>]
    def each_connected_synapses
      if block_given?
        @synapses.each { |synapse| yield(synapse) if synapse.connected? }
      else
        @synapses.select { |synapse| synapse.connected? }.each
      end
    end
    alias_method :each_connected, :each_connected_synapses

    # @todo
    #
    #
    def previous_active_connected_synapses
      @previous_connected_synapses.select { |s| s.was_active?(:active) }
    end

    # @todo
    #
    #
    def active_connected_synapses
      @synapses.select { |s| s.connected? && s.active?(:active) }
    end

    # This method returns the number of synapses that are active due to the
    # given state
    #
    # @param (see #active?)
    # @return [Integer] the number of matching synapses
    def activity(state = :active)
      @synapses.count { |synapse| synapse.active?(state) }
    end

    # This method returns the number of <b>connected</b> synapses that are
    # active due to the given state
    #
    # @param (see #activity)
    # @return (see #activity)
    def connected_activity(state = :active)
      @synapses.count { |synapse| synapse.connected? && synapse.active?(state) }
    end

    # This method returns the previous number of synapses that are
    # active due to the given state
    #
    # @param (see #activity)
    # @return (see #activity)
    def previous_activity(state = :active)
      @synapses.count { |synapse| synapse.was_active?(state) }
    end

    # This method returns the previous number of <b>connected</b> synapses that
    # are active due to the given state
    #
    # @param (see #activity)
    # @return (see #activity)
    def previous_connected_activity(state = :active)
      @synapses.count { |synapse|
        synapse.was_connected? && synapse.was_active?(state)
      }
    end

    # This method returns <b>true</b> if the number of <b>connected</b> synapses
    # that are active due to the given state is greater than
    # {#activation_threshold}.
    #
    # @param [Symbol] state either <b>:active</b> or <b>:learning</b>
    # @return [Boolean]
    def active?(state = :active)
      connected_activity(state) >= DendriteSegment.activation_threshold
    end

    # This method returns <b>true</b> if the number of previous <b>connected</b>
    # synapses that were active due to the given state is greater than
    # {#activation_threshold}.
    #
    # @see #active?
    # @param (see #active?)
    # @return (see #active?)
    def was_active?(state = :active)
      previous_connected_activity(state) >= DendriteSegment.activation_threshold
    end

    # This method returns <b>true</b> if the number of previous
    # synapses that were active due to the given state is greater than
    # {#min_threshold}.
    #
    # @param (see #active?)
    # @return (see #active?)
    def aggressively_active?(state = :active)
      activity(state) >= DendriteSegment.min_threshold
    end

    # This method returns <b>true</b> if the number of previous
    # synapses that were active due to the given state is greater than
    # {#min_threshold}.
    #
    # @param (see #active?)
    # @return (see #active?)
    def was_aggressively_active?(state = :active)
      previous_activity(state) >= DendriteSegment.min_threshold
    end
  end
end
