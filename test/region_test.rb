require 'celluloid/autostart'
require 'minitest/autorun'

require 'htm'

include HTM

class TestRegion < MiniTest::Test
  def setup
   @region = Region.new(column_width: 4, column_height: 4, input_width: 32,
                        input_height: 32)
  end

  def test_has_size
    assert 2048, @region.size
  end

  def test_has_input_size
    assert 4096, @region.input_size
  end

  def test_neighbors
    ary = @region.send(:neighbors, @region.send(:[], 0))

    puts ary
  end
end
