$:.unshift File.dirname(__FILE__) # for running in foreground in dev
$KCODE = 'u'
require 'rubygems'
gem 'activesupport', '<=1.4.4'
gem 'activerecord', '<=1.15.6'
gem 'mongrel', '<=1.1.2'
gem 'camping', '>=1.5'
require 'active_support'
require 'active_record'
require 'camping'
require 'camping/server'
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

  def state_secret
    Junebug.config['secret']
  end

  def self.create
    Junebug::Models.create_schema :assume => (Junebug::Models::Page.table_exists? ? 1.0 : 0.0)
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

  app = Rack::Builder.new do
    map Junebug.config['sitepath'] do
      use Rack::ShowExceptions
      use Camping::Server::XSendfile
      run Junebug
    end
  end

  puts "** Junebug is running at http://#{Junebug.config['host']}:#{Junebug.config['port']}#{Junebug.config['sitepath']}"

  Rack::Handler::Mongrel.run app, :Host => Junebug.config['host'], :Port => Junebug.config['port']
end
