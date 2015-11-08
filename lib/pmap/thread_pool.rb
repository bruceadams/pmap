# Internal: A thread pool for managing the threads used by the pmap functions
#
# Example:
#
#   pool = PMap::ThreadPool.new(16)
#   array.each do |item|
#     pool.schedule do
#       item.some_io_intense_operation
#     end
#   end
#
#   pool.shutdown
#
module PMap
  class ThreadPool

    # Public: Initializes a new thread pool
    #
    # max - the maximum number of threads to spawn
    #
    def initialize(max)
      raise ArgumentError, "max must be at least one." unless
        max.respond_to?(:>=) && max >= 1

      @max = max
      @jobs = Queue.new
      @workers = []
    end

    # Public: Schedules a new job to run in a thread
    #
    # *args - any arguments that will be passed to the block
    # &job  - the block that will be executed on the thread
    #
    def schedule(*args, &job)
      @jobs << [job, args]
      spawn_worker if @workers.size < @max
    end

    # Public: Shuts down the thread pool and waits for any running threads to
    #         complete
    #
    def shutdown
      @workers.size.times do
        @jobs << :stop_working
      end
      @workers.each(&:join)
    end

    private

    # Private: Spawns a new thread to work on the scheduled jobs
    #
    def spawn_worker
      thread = Thread.new do
        while (command = @jobs.pop) != :stop_working
          job, args = command
          job.call(*args)
        end
      end

      @workers << thread
    end
  end
end
