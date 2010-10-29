#!/usr/bin/env ruby

require 'test/unit'
require '../lib/pmap'

class Pmap_Test < Test::Unit::TestCase

  def test_basic_range
    proc = Proc.new {|x| x*x}
    range = (1..10)
    assert_equal(range.map(&proc), range.pmap(&proc))
  end

  def test_basic_array
    proc = Proc.new {|x| x*x*x}
    array = (1..10).to_a
    assert_equal(array.map(&proc), array.pmap(&proc))
  end

  def test_time_savings
    start = Time.now
    (1..10).pmap{ sleep 1 }
    elapsed = Time.now-start
    assert(elapsed < 2, 'Parallel sleeps too slow: %.1f seconds' % elapsed)
  end

  def test_thread_limits
    start = Time.now
    (1..10).pmap(5){ sleep 1 }
    elapsed = Time.now-start
    assert(elapsed >= 2, 'Limited threads too fast: %.1f seconds' % elapsed)
    assert(elapsed <  3, 'Parallel sleeps too slow: %.1f seconds' % elapsed)
  end

end
