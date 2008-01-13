$:.unshift File.dirname(__FILE__) # for running in foreground in dev
$KCODE = 'u'
require 'rubygems'
gem 'activesupport', '<=1.4.4'
gem 'activerecord', '<=1.15.6'
gem 'mongrel', '<=1.1.2'
gem 'camping', '>=1.5'
require 'camping/session'

Camping.goes :Junebug

require 'junebug/version'
require 'junebug/helpers'
require 'junebug/models'
require 'junebug/views'
require 'junebug/controllers'

require 'yaml'
require 'mongrel'
require 'mongrel/camping'
require 'fileutils'

module Junebug
  include Camping::Session

  def self.create
    Junebug::Models.create_schema :assume => (Junebug::Models::Page.table_exists? ? 1.0 : 0.0)
    Camping::Models::Session.create_schema
  end
  
  def self.connect
    Junebug::Models::Base.establish_connection(Junebug.config['dbconnection'])
    Junebug::Models::Base.logger = Logger.new('junebug.log')
    Junebug::Models::Base.threaded_connections=false
  end

  def self.config
    @config ||= YAML.load(File.read('config.yml'))
  end
  
  def self.startpage
    "/#{Junebug.config['startpage']}"
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

  thread = server.run

  stop_method = lambda do
    puts "** Junebug is stopping"
    thread.kill
  end

  trap "INT", &stop_method
  trap "TERM", &stop_method
  
  thread.join
end
