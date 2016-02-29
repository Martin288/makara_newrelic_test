require "bundler/gem_tasks"

require "yaml"
require "active_record"
require "makara"
require "benchmark"
require 'byebug'

class User < ::ActiveRecord::Base
  self.table_name = :users
end

def connect
  config = YAML.load_file(File.dirname(__FILE__) + '/database.yml')
  ActiveRecord::Base.establish_connection(config)
  require_relative 'schema'
end

def connect_mysql
  config = YAML.load_file(File.dirname(__FILE__) + '/database-mysql.yml')
  ActiveRecord::Base.establish_connection(config)
  require_relative 'schema'
end

def connect_distributed_mysql
  config = YAML.load_file(File.dirname(__FILE__) + '/database-distributed.yml')
  ActiveRecord::Base.establish_connection(config)
  require_relative 'schema'
end

def bm
  n = 1000
  Benchmark.bmbm do |x|
    x.report(:insert){ n.times{|i| User.create(name: "Doug #{i}") } }
    x.report(:select){ n.times{|i| User.find_by(name: "Doug #{i}") } }
  end
end

def detect

  connections = ::ActiveRecord::Base.connection_handler.connection_pool_list.map do |handler|
    handler.connections
  end.flatten

  id = connections.last.object_id

  n = 1000
  Benchmark.bm do |x|
    x.report do
      n.times do
        connections = ::ActiveRecord::Base.connection_handler.connection_pool_list.map do |handler|
          handler.connections
        end.flatten

        connection = connections.detect { |cnxn| cnxn.object_id == id }
      end
    end
  end
end

def id2ref
  connections = ::ActiveRecord::Base.connection_handler.connection_pool_list.map do |handler|
    handler.connections
  end.flatten

  id = connections.last.object_id

  n = 1000
  Benchmark.bm do |x|
    x.report do
      n.times do
        ObjectSpace._id2ref(id)
      end
    end
  end
end

def fixer
  con = ActiveRecord::Base.connection
  n = 1000
  Benchmark.bm do |x|
    x.report do
      n.times do
        connection = ActiveRecord::Base.connection_handler.connection_pool_list.detect do |l|
          l.connections.detect do |c|
            c.object_id == 4
          end
        end
      end
    end
  end
end

task :bm  do
  connect
  bm
end

task :bm_nr do
  require "newrelic_rpm"
  connect
  bm
end

task :bm_mysql2 do
  connect_mysql
  bm
end

task :bm_distributed do
  connect_distributed_mysql
  bm
end

task :detect do
  connect
  detect
end

task :id2ref do
  connect
  id2ref
end

task :fixer do
  connect
  fixer
end

task :detect_mysql do
  connect_mysql
  detect
end

task :id2ref_mysql do
  connect_mysql
  id2ref
end

task :fixer_mysql do
  connect_mysql
  fixer
end

task :debug do
  require 'byebug'
  connect
  byebug
  a=1
end

