#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )

require 'test/unit'
require 'rubygems'
require 'pmap'

class Pmap_Test < Test::Unit::TestCase

  def bad_test_noproc_range
    range = (1..10)
    assert_equal(range.map, range.pmap)
  end

  def test_basic_range
    proc = Proc.new {|x| x*x}
    range = (1..10)
    assert_equal(range.map(&proc), range.pmap(&proc))
  end

  def bad_test_noproc_array
    array = (1..10).to_a
    assert_equal(array.map, array.pmap)
  end

  def test_basic_array
    proc = Proc.new {|x| x*x*x}
    array = (1..10).to_a
    assert_equal(array.map(&proc), array.pmap(&proc))
  end

  def test_time_savings
    start = Time.now
    (1..10).peach{ sleep 1 }
    elapsed = Time.now-start
    assert(elapsed < 2, 'Parallel sleeps too slow: %.1f seconds' % elapsed)
  end

  def test_bad_thread_limits
    assert_raise(ArgumentError) {(1..10).pmap(-1){ sleep 1 }}
    assert_raise(ArgumentError) {(1..10).peach(0){ sleep 1 }}
    assert_raise(ArgumentError) {(1..10).peach(0.99){ sleep 1 }}
    assert_raise(ArgumentError) {(1..10).pmap('a'){ sleep 1 }}
    assert_raise(ArgumentError) {(1..10).peach([1,2,3]){ sleep 1 }}
  end

  def test_thread_limits
    start = Time.now
    (1..10).pmap(5){ sleep 1 }
    elapsed = Time.now-start
    assert(elapsed >= 2, 'Limited threads too fast: %.1f seconds' % elapsed)
    assert(elapsed <  3, 'Parallel sleeps too slow: %.1f seconds' % elapsed)
  end

  def test_defaut_thread_limit
    start = Time.now
    (1..128).pmap{ sleep 1 }
    elapsed = Time.now-start
    assert(elapsed >= 2, 'Limited threads too fast: %.1f seconds' % elapsed)
    assert(elapsed <  3, 'Parallel sleeps too slow: %.1f seconds' % elapsed)
  end
end
