require 'active_record/connection_adapters/makara_mysql2_adapter'

module ActiveRecord
  module ConnectionHandling
    def distributed_mysql_connection(config)
      ActiveRecord::ConnectionAdapters::DistributedMysqlAdapter.new(config)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class DistributedMysqlAdapter < ActiveRecord::ConnectionAdapters::MakaraMysql2Adapter
      attr_reader :previous_context, :current_context

      def initialize(config)
        super

        @extended_sticky = @config_parser.makara_config[:extended_sticky]
        @extended_sticky = true if @extended_sticky.nil?
      end

      # 扩展 makara 内置的 needs_master? 方法，支持基于用户会话的主库粘连，粘连时间根据配置决定
      def needs_master?(method_name, args)
        # 允许禁用 sticky 特性
        return super unless @sticky && @extended_sticky && current_user_id.present?

        # 捕捉到写操作
        sql = args.first.to_s
        if method_name.to_s.eql?("execute") && "COMMIT".eql?(sql)
          ttl_log("write! This will be expired in #{@ttl} seconds.")
          Rails.cache.write(user_cache_key, 1, expires_in: @ttl)

          return true
        end

        need_master = super
        if !need_master && in_twindow? && sql_slave_matchers.any?{|m| sql =~ m }
          ttl_log("#{method_name}, #{sql}")
          true
        else
          need_master
        end
      end

      def with_new_context
        @current_context  = Makara::Context.get_current
        @previous_context = Makara::Context.get_previous
        @previous_extended_sticky = @extended_sticky

        Makara::Context.set_current(Makara::Context.generate)
        Makara::Context.set_previous(Makara::Context.generate)
        @extended_sticky = false

        yield if block_given?
      ensure
        Makara::Context.set_current(current_context)
        Makara::Context.set_previous(previous_context)
        @extended_sticky = @previous_extended_sticky
        @previous_extended_sticky = nil
      end

      private
      def ttl_logger
        @ttl_logger ||= Logger.new("log/makara_read_ttl.log")
      end

      def ttl_log(content, type = :info)
        ttl_logger.send(:info, "T-#{current_request_id} U-#{current_user_id}: #{content}")
      end

      def user_cache_key
        "_makara_#{current_user_id}"
      end

      def in_twindow?
        return false
        Rails.cache.read(user_cache_key).present?
      end

      def current_user_id
        Thread.current.thread_variable_get(:user_id)
      end

      def current_request_id
        Thread.current.thread_variable_get(:request_id)
      end
    end
  end
end
