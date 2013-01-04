require 'minitest/autorun'
require 'minitest/colorer'
require 'minitest/mock'

require 'htm/input_cell'

include HTM

class TestInputCell < MiniTest::Unit::TestCase
  def setup
    @mock = MiniTest::Mock.new

    @current_input = [0b0, 0b1, 0b1, 0b0, 0b0, 0b0, 0b1, 0b1, 0b0, 0b1, 0b0,
                      0b1, 0b1, 0b0, 0b1, 0b0, 0b0, 0b1, 0b0, 0b1, 0b0, 0b1,
                      0b0, 0b1, 0b1]

    @previous_input = [0b1, 0b0, 0b1, 0b0, 0b1, 0b0, 0b1, 0b0, 0b0, 0b1, 0b0,
                       0b1, 0b1, 0b1, 0b1, 0b0, 0b0, 0b1, 0b1, 0b0, 0b0, 0b1,
                       0b0, 0b1, 0b0]

    @mock.expect(:current_input,  @current_input)
    @mock.expect(:previous_input, @previous_input)
    @mock.expect(:input_height,   5)

    @input = InputCell.new(3, 4, @mock)
  end

  def test_current_and_previous_learning_state_is_false
    refute @input.learning?
    refute @input.was_learning?
  end

  def test_offset_value_should_be_row_major_order
    assert_equal 23, @input.offset
  end

  def test_active
    assert_equal (@current_input[23] == 1), @input.active?
  end

  def test_was_active
    assert_equal (@previous_input[23] == 1), @input.was_active?
  end
end
