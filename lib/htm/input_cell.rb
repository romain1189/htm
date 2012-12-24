module HTM

  # This class represents a single input bit that will be connected to a
  # proximal dendrite segment.
  #
  # It offers (almost) the same API as {Cell} so that {Synapse} can behave the
  # same way either it's connected to a proximal dendrite segment (feed-forward
  # inputs) or a distal dendrite segment.
  #
  class InputCell
    attr_reader :active, :learning, :was_active, :was_learning, :x, :y

    def initialize(x, y, region)
      @region = region
      @x = x
      @y = y
    end

    # Check if the current input bit is equal to 1 or 0.
    #
    # @return [Boolean] true if input bit equals 1, false otherwise
    def active
      @region.current_input[offset] == 1
    end
    alias_method :active?, :active

    # Check if the previous input bit is equal to 1 or 0.
    #
    # @return (see #active)
    def was_active
      @region.previous_input[offset] == 1
    end
    alias_method :was_active?, :was_active

    # Check if the current learning state was active.
    # @note For a feed-forward input, this value is always false
    #
    # @return [false]
    def learning
      false
    end
    alias_method :learning?, :learning

    # Check if the previous learning state was active.
    # @note For a feed-forward input, this value is always false
    #
    # @see #learning
    # @return (see #learning)
    def was_learning
      false
    end
    alias_method :was_learning?, :was_learning

    # The source input index in a 1d array based on {#x} and {#y} indexes.
    # offset is computed as row-major order.
    def offset
      @x * @region.input_height + @y
    end
  end
end
