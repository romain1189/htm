require 'minitest/autorun'
require 'htm/cell'

include HTM

class TestCell < MiniTest::Unit::TestCase
  def setup
    @cell = Cell.new
  end

  def test_all_current_and_previous_states_should_be_false_after_initialize
    refute @cell.active?
    refute @cell.was_active?
    refute @cell.learning?
    refute @cell.was_learning?
    refute @cell.predictive?
    refute @cell.was_predictive?
  end

  def test_is_enumerable
    assert_kind_of Enumerable, @cell
  end
end
