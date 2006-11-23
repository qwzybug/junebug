require 'junebug/config'

namespace :update do

  desc "Update deploy directory"
  task :deploydir do
    mv 'static', 'public', :force => true
  end

  desc "Update stylesheets"
  task :stylesheets do
    junebug_root = Junebug::Config.rootdir
    cp_r File.join(junebug_root, 'deploy', 'public'), '.'
  end

  desc "Update rakefile"
  task :rakefile do
    junebug_root = Junebug::Config.rootdir
    cp File.join(junebug_root, 'deploy', 'Rakefile'), '.'
  end

  desc "Update everything"
  task :everything => [:deploydir, :stylesheets, :rakefile] do

  end

end