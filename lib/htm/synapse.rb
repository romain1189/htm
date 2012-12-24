module HTM
  # This class represents a synapse. contains a permanence value and the
  # source input index.
  class Synapse

    # A synapse is considered connected when its permanence value is above this
    # threshold
    PERMANENCE_THRESHOLD = 0.2

    INITIAL_PERMANENCE = 0.3

    # Amount by which a synapse permanence is incremented
    PERMANENCE_INCREMENT = 0.015

    # Amount by which a synapse permanence is decremented
    PERMANENCE_DECREMENT = 0.005

    # How many synapses must fire on a segment for it to be even considered
    # for learning
    MIN_SYNAPSES_PER_SEGMENT_THRESHOLD = 1

    attr_accessor :permanence

    class << self
      attr_accessor :threshold, :incrementation_value, :decrementation_value

      def threshold=(value)
        @threshold = value if value.between?(0, 1)
      end

      def incrementation_value=(value)
        @incrementation_value = value if value.between?(0, 1)
      end

      def decrementation_value=(value)
        @decrementation_value = value if value.between?(0, 1)
      end
    end

    @threshold = PERMANENCE_THRESHOLD
    @incrementation_value = PERMANENCE_INCREMENT
    @decrementation_value = PERMANENCE_DECREMENT

    #
    # @param [Integer] x the column index in the source input
    # @param [Integer] y the row index in the source input
    # @param [Region] region the region
    # @param [Numeric] permanence the initial permanence of the synapse (should
    #   be between 0 and 1)
    def initialize(input, permanence = INITIAL_PERMANENCE)
      if permanence.between?(0, 1)
        @permanence = permanence
      else
        @permanence = INITIAL_PERMANENCE
      end

      @input = input

      @was_connected = false
    end

    # Advance synapse state to next time step
    #
    # @todo check if {#connected?} caching is necessary
    def tick!
      @was_connected = connected?
    end

    # Test to see if the synapse can be considered as connected (permanence
    # attribute is superior than threshold)
    #
    # @return [Boolean]
    def connected?
      @permanence >= Synapse.threshold
    end

    # Cache if the synapse could be considered as connected (permanence
    # attribute was superior than threshold at previous time step)
    #
    # @see #connected?
    # @return (see #connected?)
    def was_connected?
      @was_connected
    end

    # This method returns <b>true</b> if the synapse is active due to the given
    # state at current timestep.
    # @note to be considered active, the synapse has to be connected
    #
    # @param [Symbol] state either <b>:active</b> or <b>:learning</b>
    # @return [Boolean] <b>true</b>
    def active?(state)
      return false unless connected?

      case state
      when :active then @input.active?
      when :learning then @input.learning? && @input.active?
      else false
      end
    end

    # This method returns <b>true</b> if the synapse is active due to the given
    # state at previous timestep.
    # @note to be considered active, the synapse has to be connected
    #
    # @see #active?
    # @param (see #active?)
    # @return (see #active?)
    def was_active?(state)
      return false unless was_connected?

      case state
      when :active then @input.was_active?
      when :learning then @input.was_learning? && @input.was_active?
      else false
      end
    end

    # Set the new permanence value (Should be between 0 and 1).
    #
    # @param [Float] n the new value
    # @return [Float] the permanence value
    def permanence=(n)
      @permanence = n if n.between?(0, 1)
    end

    # Increase the permanence attribute by given amount. {incrementation_value}
    # value is used if no amount is given.
    #
    # @param [Float] amount the amount by which the permanence is increased
    # @return [Float] the new permanence value
    def increase_permanence(amount = Synapse.incrementation_value)
      @permanence = [1, amount + @permanence].min
    end

    # Decrease the permanence attribute by given amount. {decrementation_value}
    # value is used if no amount is given.
    #
    # @param [Float] amount the amount by which the permanence is decreased
    # @return [Float] the new permanence value
    def decrease_permanence(amount = Synapse.decrementation_value)
      @permanence = [0, @permanence - amount].max
    end

    # Update the permanence value such that if {#connected?} returns
    # <b>true</b>, the permanence value is increased, otherwise the value is
    # decreased.
    #
    # @return [Float] the new permanence value
    def update_permanence
      if connected?
        increase_permanence
      else
        decrease_permanence
      end
    end

  end
end
