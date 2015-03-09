require 'thread' unless defined?(Mutex)

# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

module PMap
  class DummyOutput
    def []=(idx, val)
    end
  end

  def self.included(base)
    base.class_eval do
      attr_accessor :max_thread_count
      attr_accessor :min_thread_count
      attr_accessor :active_record_object
      attr_accessor :previous_pool_size

      # Parallel "map" for any Enumerable.
      # Requires a block of code to run for each Enumerable item.
      # [thread_count] is number of threads to create. Optional.
      def pmap(options_or_thread_count = {}, &proc)
        configure(options_or_thread_count)
        in_array = self.to_a        # I'm not sure how expensive this is...
        out_array = Array.new(in_array.size)
        processing_started
        process_core(max_thread_count, in_array, out_array, &proc)
        processing_completed
        out_array
      end

      def configure(options_or_thread_count = {})
        # This is ONLY here to provide support for the previous version of #pmap which just passes
        # the thread count
        if options.is_a? Numeric
          self.max_thread_count = options_or_thread_count
        else
          self.max_thread_count = options_or_thread_count.try(:[],:thread_count)
          self.active_record_object = options_or_thread_count.try(:[],:active_record_object)
        end
      end

      def processing_started
        increase_active_record_pool_size
      end

      def processing_completed
        reset_active_record_pool_size
      end

      def increase_active_record_pool_size
        if active_record_object && active_record_object.connected?
          self.previous_pool_size = active_record_object.connection_pool.instance_variable_get('@size') || 0
          if previous_pool_size < min_thread_count
            active_record_object.connection_pool.instance_variable_set('@size', min_thread_count)
          end
        end
      end

      def reset_active_record_pool_size
        if active_record_object && active_record_object.connected? && previous_pool_size
          active_record_object.connection_pool.instance_variable_set('@size', previous_pool_size)
        end
      end

      def process_core(thread_count, in_array, out_array, &proc)
        self.min_thread_count = thread_count(thread_count, in_array)
        size = in_array.size

        semaphore = Mutex.new
        index = -1                  # Our use of index is protected by semaphore

        threads = (0...min_thread_count).map {
          Thread.new {
            i = nil
            while (semaphore.synchronize {i = (index += 1)}; i < size)
              out_array[i] = yield(in_array[i])
            end
          }
        }
        threads.each {|t| t.join}
      end
      private :process_core

      def thread_count(user_requested_count, items)
        user_requested_count ||= $pmap_default_thread_count
        raise ArgumentError, "thread_count must be at least one." unless
          user_requested_count.respond_to?(:>=) && user_requested_count >= 1
        [user_requested_count, items.size].min
      end
      private :thread_count

      # Parallel "each" for any Enumerable.
      # Requires a block of code to run for each Enumerable item.
      # [thread_count] is number of threads to create. Optional.
      def peach(thread_count=nil, &proc)
        process_core(thread_count, self.to_a, DummyOutput.new, &proc)
        self
      end
    end
  end
end

module Enumerable
  include PMap
end
