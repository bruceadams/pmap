
# I'd prefer to create this as a module named "Pmap" and then poke
# "Pmap" into "Enumerable". I haven't figured out how to do it.
# So, I directly reopen "Enumerable" and add "p" methods...

require 'thread' unless defined?(Mutex)

module Enumerable
  def pmap(tcount=nil, &b)
    # This seems overly fussy... (code smell)
    in_array = self.to_a        # I'm not sure how expensive this is...
    my_size = in_array.size
    out_array = Array.new(my_size)
    semaphore = Mutex.new
    index = -1                  # Our use of index is protected by semaphore
    threads = (0...(tcount || my_size)).map {
      Thread.new {
        i = nil
        while (semaphore.synchronize {i = (index += 1)}; i < my_size)
          out_array[i] = yield(in_array[i])
        end
      }
    }
    threads.each {|t| t.join}
    out_array
  end

  # This is doing some extra work: building a return array that is
  # thrown away.  How can I share the core code of "pmap" here,
  # omitting the output array creation?
  def peach(tcount=nil, &b)
    pmap(tcount, &b)
    self
  end
end
