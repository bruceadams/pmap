
# I'd prefer to create this as a module named "Pmap" and then poke
# "Pmap" into "Enumerable". I haven't figured out how to do it.
# So, I directly reopen "Enumerable" and add "p" methods...

module Enumerable
  # FIXME: Add support for a limited thread pool size.
  def pmap(thread_count=nil, &b)
    in_array = self.to_a        # I'm not sure how expensive this is...
    out_array = Array.new(in_array.size)
    threads = (0...in_array.size).map {|j|
      Thread.new(j) {|x| out_array[x] = yield(in_array[x])}
    }
    threads.each {|t| t.join}
    out_array
  end

  # This is doing some extra work: building a return array that we throw away.
  def peach(thread_count=nil, &b)
    pmap(&b)
    self
  end
end
