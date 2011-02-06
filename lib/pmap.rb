
# I'd prefer to create this as a module named "Pmap" and then poke
# "Pmap" into "Enumerable". I haven't figured out how to do it.
# So, I directly reopen "Enumerable" and add "p" methods...

require 'thread' unless defined?(Mutex)

# Global variable for the default thread pool size.
$pmap_default_thread_count ||= 64

module Enumerable
  # Parallel "map" for any Enumerable.
  # Requires a block of code to run for each Enumerable item.
  # [thread_count] is number of threads to create. Optional.
  def pmap(thread_count=nil, &proc)
    raise ArgumentError, "thread_count must be at least one." unless
      thread_count.nil? or (thread_count.respond_to?(:>=) and thread_count >= 1)
    # This seems overly fussy... (code smell)
    in_array = self.to_a        # I'm not sure how expensive this is...
    size = in_array.size
    thread_count = [thread_count||$pmap_default_thread_count, size].min
    out_array = Array.new(size)
    semaphore = Mutex.new
    index = -1                  # Our use of index is protected by semaphore
    threads = (0...thread_count).map {
      Thread.new {
        i = nil
        while (semaphore.synchronize {i = (index += 1)}; i < size)
          out_array[i] = yield(in_array[i])
        end
      }
    }
    threads.each {|t| t.join}
    out_array
  end

  # Parallel "each" for any Enumerable.
  # Requires a block of code to run for each Enumerable item.
  # [thread_count] is number of threads to create. Optional.
  def peach(thread_count=nil, &proc)
    # This is doing some extra work: building a return array that is
    # thrown away. How can I share the core code of "pmap" here and omit
    # the output array creation?
    pmap(thread_count, &proc)
    self
  end
end
