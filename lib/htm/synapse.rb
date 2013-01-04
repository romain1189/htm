module HTM
  # This class represents a synapse. contains a permanence value and the
  # source input index.
  class Synapse

    # A synapse is considered connected when its permanence value is above this
    # threshold
    PERMANENCE_THRESHOLD = 0.2

    # Amount by which a synapse permanence is incremented
    PERMANENCE_INCREMENT = 0.015

    # Amount by which a synapse permanence is decremented
    PERMANENCE_DECREMENT = 0.005

    # The initial permanence for a synapse
    INITIAL_PERMANENCE = 0.3

    attr_accessor :permanence
    attr_reader :input

    class << self
      attr_accessor :threshold, :incrementation_value, :decrementation_value,
                    :initial_permanence

      def threshold=(value)
        @threshold = value if value.between?(0, 1)
      end

      def incrementation_value=(value)
        @incrementation_value = value if value.between?(0, 1)
      end

      def decrementation_value=(value)
        @decrementation_value = value if value.between?(0, 1)
      end

      def initial_permanence=(value)
        @initial_permanence = value if value.between?(0, 1)
      end
    end

    @threshold = PERMANENCE_THRESHOLD
    @incrementation_value = PERMANENCE_INCREMENT
    @decrementation_value = PERMANENCE_DECREMENT
    @initial_permanence = INITIAL_PERMANENCE

    #
    # @param [InputCell, Cell]
    # @param [Numeric] permanence the initial permanence of the synapse (should
    #   be between 0 and 1)
    def initialize(input, permanence = Synapse.initial_permanence)
      if permanence.between?(0, 1)
        @permanence = permanence
      else
        @permanence = Synapse.initial_permanence
      end

      @input = input

      @was_connected = false
    end

    # Gives a change to the synapse to update his state before a new input is
    # given to the region
    #
    # @return [void]
    def before_tick!
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
    # @note to be considered active, the synapse has not to be connected
    #
    # @param [Symbol] state either <b>:active</b> or <b>:learning</b>
    # @return [Boolean] <b>true</b>
    def active?(state)
      case state
      when :active then @input.active?
      when :learning then @input.learning? && @input.active?
      else false
      end
    end

    # This method returns <b>true</b> if the synapse is active due to the given
    # state at previous timestep.
    # @note to be considered active, the synapse has not to be connected
    #
    # @see #active?
    # @param (see #active?)
    # @return (see #active?)
    def was_active?(state)
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

    # Returns the row of the input source if the synapse is attached to a
    # proximal dendrite segment, always 0 otherwise
    #
    # @return [Integer]
    def input_x
      if @input.respond_to?(:x)
        @input.x
      else
        0
      end
    end

    # Returns the column of the input source if the synapse is attached to a
    # proximal dendrite segment, always 0 otherwise
    #
    # @return [Integer]
    def input_y
      if @input.respond_to?(:y)
        @input.y
      else
        0
      end
    end
  end
end
