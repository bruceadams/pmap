module ActiveRecord
  class Base
    def pmap_reset_connection_pool_size
      if connected?
        connection_pool.pmap_reset_connection_pool_size
      else
        fail "Unable to reset connection pool size as ActiveRecord::Base is not connected"
      end
    end

    def pmap_set_connection_pool_size(val)
      if connected?
        connection_pool.pmap_set_connection_pool_size(val)
      else
        fail "Unable to set connection pool size as ActiveRecord::Base is not connected"
      end
    end
  end

  module ConnectionAdapters
    class ConnectionPool
      def pmap_reset_connection_pool_size
        if @pmap_old_size
          @size = @pmap_old_size
          @pmap_old_size = nil
        end
      end

      def pmap_set_connection_pool_size(val)
        if @size < val
          @pmap_old_size = @size
          @size = val
        else
          @pmap_old_size = nil
        end
      end
    end
  end
end
