require 'junebug'

namespace :dump do

  desc 'Dump page and user data'
  task :all => [:pages, :users]

  desc 'Dump wiki pages'
  task :pages do
    Junebug.connect
    
    fixtures_dir = File.join('.', 'dump')
    
    # open fixtures file
    File.open(File.join(fixtures_dir, "junebug_pages.yml"), 'w') do |file|
    
      # grab all pages
      objs = Junebug::Models::Page.find(:all)
      data = []
      objs.each do |obj|
        data << obj.attributes
      end
    
      file.write data.to_yaml
    end
  
    puts "Got pages and put them in #{fixtures_dir}."
  end

  desc 'Dump user data'
  task :users do
    Junebug.connect
    
    fixtures_dir = File.join('.', 'dump')
    
    # open fixtures file
    File.open(File.join(fixtures_dir, "junebug_users.yml"), 'w') do |file|
    
      # grab all users
      objs = Junebug::Models::User.find(:all)
      data = []
      objs.each do |obj|
        data << obj.attributes
      end
    
      file.write data.to_yaml
    end
  
    puts "Got users and put them in #{fixtures_dir}."
  end



end