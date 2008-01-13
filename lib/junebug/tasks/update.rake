require 'junebug'
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

  desc "Update rakefile and wiki-runner"
  task :rakefile do
    junebug_root = Junebug::Config.rootdir
    cp File.join(junebug_root, 'deploy', 'Rakefile'), '.'
    cp File.join(junebug_root, 'deploy', 'wiki'), '.'
  end

  desc "Update help pages"
  task :help do
    Junebug.connect
    pages_file = File.dirname(__FILE__) + "/../../../dump/junebug_pages.yml"
    YAML.load_file(pages_file).each do |page_data|
      # For consistency...
      page_data.delete('id')
      page_data.delete('version')
      page_data.delete('updated_at')
      page_data.delete('created_at')
      page_data['user_id'] = 1
      page = Junebug::Models::Page.find_by_title(page_data['title'])
      if page
        page.update_attributes(page_data) unless page.body == page_data['body']
      else
        Junebug::Models::Page.create(page_data)
      end
    end
  end

  desc "Update everything"
  task :everything => [:deploydir, :stylesheets, :rakefile, :help] do

  end

end