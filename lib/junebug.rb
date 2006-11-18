$:.unshift File.dirname(__FILE__) # for running in foreground in dev

require 'rubygems'
require_gem 'camping', '>=1.5'
require 'camping/session'

Camping.goes :Junebug

require 'junebug/helpers'
require 'junebug/models'
require 'junebug/views'
require 'junebug/controllers'

require 'yaml'
require 'mongrel'
require 'fileutils'

module Junebug
  include Camping::Session
  
  VERSION='0.0.15'

  def self.create
    Junebug::Models.create_schema :assume => (Junebug::Models::Page.table_exists? ? 1.0 : 0.0)
    Camping::Models::Session.create_schema
  end
  
  def self.connect
    Junebug::Models::Base.establish_connection :adapter => 'sqlite3', :database => 'junebug.db'
    Junebug::Models::Base.logger = Logger.new('junebug.log')
    Junebug::Models::Base.threaded_connections=false
  end

  def self.config
    @config ||= YAML.load(File.read('config.yml'))
  end
  
  def self.startpage
    "#{Junebug.config['url']}/#{Junebug.config['startpage']}"
  end
end


if __FILE__ == $0 || ENV['DAEMONS_ARGV']
  # When using daemons, the current dir is /
  # So we need to set it to the junebug root
  FileUtils.cd ENV['JUNEBUG_ROOT'] if ENV['JUNEBUG_ROOT']
  Junebug.connect
  Junebug.create

  server = Mongrel::Camping::start( Junebug.config['host'], Junebug.config['port'], Junebug.config['sitepath'], Junebug)

  puts "** Junebug is running at http://#{Junebug.config['host']}:#{Junebug.config['port']}#{Junebug.config['sitepath']}"

  server.run.join
end
