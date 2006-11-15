require 'junebug'
require 'junebug/models'
require 'active_record'

namespace :dump do

  desc 'Dump wiki pages'
  task :pages do
    fixtures_dir = File.join('.', 'dump')
  
    # clean out fixtures dir
    puts "fixtures_dir: #{fixtures_dir}"
    Dir[File.join(fixtures_dir, '*')].each { |f| rm_f(f, :verbose => false) }
  
    # open db connection
    ActiveRecord::Base.establish_connection( :adapter => "sqlite3", :database  => "./junebug.db")
  
    # open fixtures file
    File.open(File.join(fixtures_dir, "junebug_pages.yml"), 'w') do |file|
    
      # grab all pages
      pages = Junebug::Models::Page.find(:all)
      page_data = []
      pages.each do |page|
        page_data << page.attributes
      end
    
      file.write page_data.to_yaml
    end
  
    puts "Got pages and put them in #{fixtures_dir}."
  end

end