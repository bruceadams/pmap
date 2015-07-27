require 'thread' unless defined?(Mutex)
require 'pmap/active_record'

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

      # Parallel "map" for any Enumerable.
      # Requires a block of code to run for each Enumerable item.
      # [thread_count] is number of threads to create. Optional.
      def pmap(options_or_thread_count = {}, &proc)
        in_array = self.to_a        # I'm not sure how expensive this is...
        out_array = Array.new(in_array.size)
        configure_pmap(in_array.size, options_or_thread_count)
        increase_active_record_pool_size
        process_core(in_array, out_array, &proc)
        reset_active_record_pool_size
        out_array
      end

      # Parallel "each" for any Enumerable.
      # Requires a block of code to run for each Enumerable item.
      # [thread_count] is number of threads to create. Optional.
      def peach(options_or_thread_count = {}, &proc)
        in_array = self.to_a
        configure_pmap(in_array.size, options_or_thread_count)
        increase_active_record_pool_size
        process_core(in_array, DummyOutput.new, &proc)
        reset_active_record_pool_size
        self
      end

      def configure_pmap(array_size, options_or_thread_count = {})
        # This is ONLY here to provide support for the previous version of #pmap which just passes
        # the thread count
        if options_or_thread_count.is_a? Numeric
          self.max_thread_count = options_or_thread_count
        else
          self.max_thread_count = options_or_thread_count[:thread_count] if options_or_thread_count[:thread_count]
          if options_or_thread_count[:active_record_object]
            self.active_record_object = options_or_thread_count[:active_record_object]
            fail TypeError, "Invalid Active Record object" unless self.active_record_object.respond_to?(:pmap_set_connection_pool_size)
          end
        end
        self.min_thread_count = thread_count(max_thread_count, array_size)
      end
      private :configure_pmap

      def increase_active_record_pool_size
        active_record_object.pmap_set_connection_pool_size(min_thread_count) if active_record_object
      end
      private :increase_active_record_pool_size

      def reset_active_record_pool_size
        active_record_object.pmap_reset_connection_pool_size if active_record_object
      end
      private :reset_active_record_pool_size

      def process_core(in_array, out_array, &proc)
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

      def thread_count(user_requested_count, array_size)
        user_requested_count ||= $pmap_default_thread_count
        raise ArgumentError, "thread_count must be at least one." unless
          user_requested_count.respond_to?(:>=) && user_requested_count >= 1
        [user_requested_count, array_size].min
      end
      private :thread_count
    end
  end
end

module Enumerable
  include PMap
end
