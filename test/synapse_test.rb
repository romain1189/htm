require 'minitest/autorun'
require 'minitest/colorer'
require 'minitest/mock'

require 'htm/synapse'

include HTM

class TestSynapse < MiniTest::Unit::TestCase
  def setup
    @mock = MiniTest::Mock.new

    @mock.expect(:learning?,     true)
    @mock.expect(:active?,       true)
    @mock.expect(:was_learning?, true)
    @mock.expect(:was_active?,   true)

    @synapse = Synapse.new(@mock)
  end

  def test_synapse_setup_values_are_coherent
    Synapse.threshold = 2
    Synapse.incrementation_value = 2
    Synapse.decrementation_value = 2

    assert_includes (0..1), Synapse.threshold
    assert_includes (0..1), Synapse.incrementation_value
    assert_includes (0..1), Synapse.decrementation_value

    Synapse.threshold = -1
    Synapse.incrementation_value = -1
    Synapse.decrementation_value = -1

    assert_includes (0..1), Synapse.threshold
    assert_includes (0..1), Synapse.incrementation_value
    assert_includes (0..1), Synapse.decrementation_value
  end

  def test_synapse_permanence_is_in_correct_range
    assert_includes (0..1), @synapse.permanence
  end

  def test_synapse_connected_above_threshold
    @synapse.permanence = 0.999
    assert @synapse.connected?
  end

  def test_synapse_disconnected_below_threshold
    @synapse.permanence = 0.001
    refute @synapse.connected?
  end

  def test_incremented_permanence_should_not_exceed_max
    @synapse.permanence = 0.8
    @synapse.increase_permanence(1)
    assert_includes (0..1), @synapse.permanence
  end

  def test_decremented_permanence_should_not_be_below_min
    @synapse.permanence = 0.2
    @synapse.decrease_permanence(1)
    assert_includes (0..1), @synapse.permanence
  end

  def test_was_not_connected_after_initialize
    refute @synapse.was_connected?
  end

  def test_active_only_if_connected
    @synapse.permanence = 0.1

    refute @synapse.active?(:active)
    refute @synapse.active?(:learning)
  end

  def test_was_active_only_if_was_connected
    refute @synapse.was_active?(:active)
    refute @synapse.was_active?(:learning)
  end

  def test_active_only_for_active_and_learning_states
    @synapse.permanence = 0.9

    assert @synapse.active?(:active)
    assert @synapse.active?(:learning)
    refute @synapse.active?(:invalid_state)
  end

  def test_tick_should_assign_was_connected_to_connected
    connected = @synapse.connected?
    @synapse.tick!
    assert_equal connected, @synapse.was_connected?
  end

  def test_was_active_only_for_active_and_learning_states
    @synapse.permanence = 0.9
    @synapse.tick!

    assert @synapse.was_active?(:active)
    assert @synapse.was_active?(:learning)
    refute @synapse.was_active?(:invalid_state)
  end
end
