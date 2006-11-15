require 'fileutils'

require 'junebug'
require 'junebug/models'

module Junebug
  module Generator
    extend self
  
    def generate(args)
      src_root = File.dirname(__FILE__) + '/../../deploy'
      app = ARGV.first
      FileUtils.cp_r(src_root, app)
      FileUtils.chmod(0755, app+'/wiki')
      FileUtils.cd app
      Junebug.connect
      Junebug.create
      
      user = Junebug::Models::User.find(1)
      
      puts <<EOS

***********************************

Welcome to Junebug!

To start your new wiki, do the following:

> cd #{app}
> ./wiki run

Open your browser to http://#{Junebug.config['host']}:#{Junebug.config['port']}#{Junebug.config['sitepath']}

Your admin account is:

username: #{user.username}
password: #{user.password}

For more information about running and configuring Junebug,
go to http://www.junebugwiki.com

Submit bug reports to tim.myrtle@gmail.com

EOS
    end
    
  end
end
