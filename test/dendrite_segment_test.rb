require 'minitest/autorun'
require 'minitest/colorer'
require 'minitest/mock'

require 'htm/dendrite_segment'

include HTM

class TestDendriteSegment < MiniTest::Unit::TestCase
  def setup
    @segment = DendriteSegment.new
  end

  def test_sequence_is_false_after_initialize
    refute @segment.sequence?
  end

  def test_min_threshold_is_below_activation_threshold
    DendriteSegment.min_threshold = 15
    DendriteSegment.activation_threshold = 12

    assert DendriteSegment.min_threshold <= DendriteSegment.activation_threshold

    DendriteSegment.activation_threshold = 23
    DendriteSegment.min_threshold = 25

    assert DendriteSegment.min_threshold <= DendriteSegment.activation_threshold
  end

  def test_is_enumerable
    assert_kind_of Enumerable, @segment
  end

  def test_each_connected_yields_only_connected_synapses
    25.times {
      bool = rand >= 0.5
      @segment << MiniTest::Mock.new.expect(:connected?, bool)
                                    .expect(:connected?, bool)
    }

    assert @segment.each_connected.all? { |syn| syn.connected? }
  end

  def test_activity_counts_only_active_synapses
    n = 0
    25.times {
      bool = rand >= 0.5
      n += 1 if bool

      @segment << MiniTest::Mock.new.expect(:active?, bool, [:active])
                                    .expect(:was_active?, !bool, [:active])
    }

    assert_equal n, @segment.activity
    assert_equal 25 - n, @segment.previous_activity
  end

  def test_connected_activity_counts_connected_and_active_synapses
    n = 0
    n2 = 0
    25.times {
      active = rand >= 0.5
      connected = rand >= 0.5
      n += 1 if active && connected
      n2 += 1 if !active && !connected

      @segment << MiniTest::Mock.new.expect(:active?, active, [:active])
                                    .expect(:connected?, connected)
                                    .expect(:was_active?, !active, [:active])
                                    .expect(:was_connected?, !connected)
    }

    assert_equal n, @segment.connected_activity
    assert_equal n2, @segment.previous_connected_activity
  end

  def test_active_if_connected_activity_above_activation_threshold
    DendriteSegment.min_threshold = 1
    DendriteSegment.activation_threshold = 2

    segment = DendriteSegment.new
    3.times { |n|
      segment << MiniTest::Mock.new.expect(:active?, n.even?, [:active])
                                    .expect(:connected?, n.even?)
                                    .expect(:was_active?, n.even?, [:active])
                                    .expect(:was_connected?, n.even?)
    }

    assert segment.active?
    assert segment.was_active?

    segment = DendriteSegment.new
    3.times { |n|
      segment << MiniTest::Mock.new.expect(:active?, n.odd?, [:active])
                                    .expect(:connected?, n.odd?)
                                    .expect(:was_active?, n.odd?, [:active])
                                    .expect(:was_connected?, n.odd?)
    }

    refute segment.active?
    refute segment.was_active?

    segment = DendriteSegment.new
    3.times { |n|
      segment << MiniTest::Mock.new.expect(:active?, n.even?, [:active])
                                    .expect(:connected?, n.odd?)
                                    .expect(:was_active?, n.odd?, [:active])
                                    .expect(:was_connected?, n.even?)
    }

    refute segment.active?
    refute segment.was_active?
  end

  def test_aggressively_active_if_activity_above_min_threshold
    DendriteSegment.min_threshold = 2
    DendriteSegment.activation_threshold = 15

    segment = DendriteSegment.new
    3.times { |n|
      segment << MiniTest::Mock.new.expect(:active?, n.even?, [:active])
                                    .expect(:was_active?, n.even?, [:active])
    }

    assert segment.aggressively_active?
    assert segment.was_aggressively_active?

    segment = DendriteSegment.new
    3.times { |n|
      segment << MiniTest::Mock.new.expect(:active?, n.odd?, [:active])
                                    .expect(:was_active?, n.odd?, [:active])
    }

    refute segment.aggressively_active?
    refute segment.was_aggressively_active?
  end

  def test_tick_saves_list_of_connected_synapses_then_tick_all_synapses
    assert false
  end
end
