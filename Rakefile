require "bundler/gem_tasks"

require "yaml"
require "active_record"
require "makara"
require "benchmark"

class User < ::ActiveRecord::Base
  self.table_name = :users
end

def connect
  config = YAML.load_file(File.dirname(__FILE__) + '/database.yml')
  ActiveRecord::Base.establish_connection(config)
  require_relative 'schema'
end

def bm
  n = 500
  Benchmark.bmbm do |x|
    x.report(:insert){ n.times{|i| User.create(name: "Doug #{i}") } }
    x.report(:select){ n.times{|i| User.find_by(name: "Doug #{i}") } }
  end
end

task :connect do
  connect
end

task :connect_nr do
  require "newrelic_rpm"
  connect
end


task :bm => :connect do
  bm
end


task :bm_nr => :connect_nr do
  bm
end
