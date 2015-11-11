require 'thread' unless defined?(Mutex)
require "pmap/thread_pool"

# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

module PMap
  # @!method pmap
  #
  #   Parallel #map for any Enumerable.
  #
  #   Requires a block of code to run for each Enumerable item.
  #
  #   @see http://ruby-doc.org/core-2.2.3/Enumerable.html#method-i-map
  #
  #   @param thread_count [Integer] maximum number of threads to create 
  #     (optional)
  #
  #   @return [Array] of mapped objects
  #

  # @!method peach
  #
  #   Parallel #each for any Enumerable.
  #
  #   Requires a block of code to run for each Enumerable item.
  # 
  #   @param thead_count [Integer] maximum number of threads to create 
  #     (optional)
  #
  #   @return [void]
  #

  # @!method peach_with_index
  #
  #   Parallel #each_with_index for any Enumerable.
  #
  #   Requires a block of code to run for each Enumerable item.
  #   
  #   @see http://ruby-doc.org/core-2.2.3/Enumerable.html#method-i-each_with_index
  #
  #   @param thread_count [Integer] maximum number of threads to create 
  #     (optional)
  #
  #   @return [void]
  #
  def self.included(base)
    base.class_eval do

      # @see PMap#pmap
      def pmap(thread_count=nil, &proc)
        Array.new.tap do |result|
          peach_with_index(thread_count) do |item, index|
            result[index] = proc.call(item)
          end
        end
      end

      # @see PMap#peach
      def peach(thread_count=nil, &proc)
        peach_with_index(thread_count) do |item, index|
          proc.call(item)
        end
        self
      end

      # @see PMap#peach_with_index
      def peach_with_index(thread_count=nil, &proc)
        thread_count ||= $pmap_default_thread_count
        pool = ThreadPool.new(thread_count)

        each_with_index do |item, index|
          pool.schedule(item, index, &proc)
        end
        pool.shutdown
        self
      end
    end
  end
end

module Enumerable
  include PMap
end
