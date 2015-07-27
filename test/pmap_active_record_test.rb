#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path( File.dirname(__FILE__) + '/../lib' )

require 'test/unit'
require 'flexmock/test_unit'
require 'rubygems'
require 'pmap'

class Pmap_Active_Record_Test < Test::Unit::TestCase
  def test_base_set_connection_pool_size
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    active_record_object = flexmock(ActiveRecord::Base.new, :connected? => true, connection_pool: connection_pool)
    connection_pool.should_receive('pmap_set_connection_pool_size').with(7).once
    active_record_object.pmap_set_connection_pool_size(7)
  end

  def test_base_set_connection_pool_size_not_connected
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    active_record_object = flexmock(ActiveRecord::Base.new, :connected? => false, connection_pool: connection_pool)
    assert_raise { active_record_object.pmap_set_connection_pool_size(7) }
  end

  def test_base_reset_connection_pool_size
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    active_record_object = flexmock(ActiveRecord::Base.new, :connected? => true, connection_pool: connection_pool)
    connection_pool.should_receive('pmap_reset_connection_pool_size').once
    active_record_object.pmap_reset_connection_pool_size
  end

  def test_base_reset_connection_pool_size_not_connected
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    active_record_object = flexmock(ActiveRecord::Base.new, :connected? => false, connection_pool: connection_pool)
    assert_raise { active_record_object.pmap_reset_connection_pool_size }
  end

  def test_connection_pool_size_higher
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    connection_pool.instance_variable_set('@size', 3)
    connection_pool.pmap_set_connection_pool_size(8)
    assert_equal(8, connection_pool.instance_variable_get('@size'))
  end

  def test_connection_pool_size_lower
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    connection_pool.instance_variable_set('@size', 8)
    connection_pool.pmap_set_connection_pool_size(3)
    assert_equal(8, connection_pool.instance_variable_get('@size'))
  end

  def test_connection_pool_reset_size_higher
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    connection_pool.instance_variable_set('@size', 3)
    connection_pool.pmap_set_connection_pool_size(8)
    connection_pool.pmap_reset_connection_pool_size
    assert_equal(3, connection_pool.instance_variable_get('@size'))
  end

  def test_connection_pool_reset_size_lower
    connection_pool = flexmock(ActiveRecord::ConnectionAdapters::ConnectionPool.new)
    connection_pool.instance_variable_set('@size', 8)
    connection_pool.pmap_set_connection_pool_size(3)
    connection_pool.pmap_reset_connection_pool_size
    assert_equal(8, connection_pool.instance_variable_get('@size'))
  end
end
