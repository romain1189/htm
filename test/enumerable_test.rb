require 'celluloid/autostart'
require 'minitest/autorun'

require 'celluloid'
require 'enumerable'

class TestEnumerable < MiniTest::Test
  def setup
    @ary = (1..25).to_a
  end

  def test_should_respond_to_monkey_patched_methods
    assert_respond_to @ary, :pmap
    assert_respond_to @ary, :peach
  end

  def test_pmap
    proc = Proc.new { |n| n ** 2 }
    assert_equal @ary.map(&proc), @ary.pmap(&proc)
  end

  # This test is stupid
  # def test_peach
  #   expected = []
  #   @ary.each { |n| expected << (n ** 2) }

  #   act = []
  #   @ary.peach { |n| act << (n ** 2) }

  #   assert_equal expected, act
  # end
end
