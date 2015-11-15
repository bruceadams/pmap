require 'thread' unless defined?(Mutex)
require "pmap/thread_pool"

# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

module PMap
  def self.included(base)
    base.class_eval do

      # Public: Parallel "map" for any Enumerable.
      #
      # thread_count - maximum number of threads to create (optional)
      #
      # Requires a block of code to run for each Enumerable item.
      #
      def pmap(thread_count=nil, &proc)
        return self unless proc

        array_mutex = Mutex.new
        Array.new.tap do |result|
          peach_with_index(thread_count) do |item, index|
            value = proc.call(item)
            array_mutex.synchronize { result[index] = value }
          end
        end
      end

      # Public: Parallel "each" for any Enumerable.
      #
      # thread_count - maximum number of threads to create (optional)
      #
      # Requires a block of code to run for each Enumerable item.
      #
      def peach(thread_count=nil, &proc)
        if proc
          peach_with_index(thread_count) do |item, index|
            proc.call(item)
          end
        end
        self
      end

      # Public: Parallel each_with_index for any Enumerable
      #
      # thread_count - maximum number of threads to create (optional)
      #
      # Requires a block of code to run for each Enumerable item.
      #
      def peach_with_index(thread_count=nil, &proc)
        return each_with_index unless proc

        thread_count ||= $pmap_default_thread_count
        pool = ThreadPool.new(thread_count)

        each_with_index do |item, index|
          pool.schedule(item, index, &proc)
        end
        pool.shutdown
        self
      end

      # Public: Parallel flat_map for any Enumerable
      #
      # thread_count - maximum number of threads to create (optional)
      #
      # Requires a block of code to run for each Enumerable item
      #
      def flat_pmap(thread_count=nil, &proc)
        pmap(thread_count, &proc).flatten(1)
      end
    end
  end
end

module Enumerable
  include PMap
end
