require 'minitest/autorun'

require 'htm'

include HTM::Geometry

class TestPoint < MiniTest::Test
  def setup
   @a = Point.new(0, 0)
   @b = Point.new(4, 4)
  end

  def test_iterates_through_other
    n = 0
    @a.through(@b) { |x, y| n += 1 }

    assert 16, n
  end

  def test_computes_distance_between_two_points
    assert_equal 5.656854249492381, @a.distance_from(@b)
    assert_equal 5.656854249492381, @b.distance_from(@a)
  end
end
