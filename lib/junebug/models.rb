require 'active_record'
require 'junebug/ext/acts_as_versioned'

module Junebug::Models

  class User < Base
    
    ROLE_USER = 0
    ROLE_ADMIN = 10
    validates_uniqueness_of :username
    validates_format_of :username, :with => /^([\w]*)$/
    validates_length_of :username, :within=>3..30
    validates_format_of :password, :with => /^([\w]*)$/
    validates_length_of :password, :within=>5..30
    has_many :pages

    def username=(text)
      write_attribute(:username, (text ? text.strip.downcase : text) )
    end

    def password=(text)
      write_attribute(:password, (text ? text.strip : text) )
    end

  end

  class Page < Base
    belongs_to :user, :class_name=>"Junebug::Models::User" # Hack to prevent camping error on initial load
    #PAGE_LINK = /\[\[([^\]|]*)[|]?([^\]]*)\]\]/
    PAGE_LINK = /\[\[([0-9A-Za-z -]+)[|]?([^\]]*)\]\]/
    #before_save { |r| r.title = r.title.underscore }
    #PAGE_LINK = /([A-Z][a-z]+[A-Z]\w+)/
    validates_uniqueness_of :title
    validates_format_of :title, :with => /^[0-9A-Za-z -]+$/
    validates_presence_of :title
    acts_as_versioned
    non_versioned_fields.push 'title'
    
    def title=(text)
      write_attribute(:title, text ? text.strip.squeeze(' ') : text)
    end
    
    def title_url
      title.gsub(' ','_')
    end
  end
  
  class Page::Version < Base
    belongs_to :user, :class_name=>"Junebug::Models::User", :foreign_key=>'user_id' # Hack to prevent camping error on initial load
  end

  class CreateJunebug < V 1.0
    def self.up
      create_table :junebug_users do |t|
        t.column :id,       :integer, :null => false
        t.column :username, :string, :null => false
        t.column :password, :string, :null => false
        t.column :role,     :integer, :default => 0
      end
      create_table :junebug_pages do |t|
        t.column :title, :string, :limit => 255
        t.column :body, :text
        t.column :user_id, :integer, :null => false
        t.column :readonly, :boolean, :default => false
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
      Page.create_versioned_table
      Page.reset_column_information
      
      # Create admin account
      admin = User.new(:role => User::ROLE_ADMIN)
      if ENV['INTERACTIVE']
        loop {
          print "Create an initial user account\n"
          print "\nEnter your username (3-30 chars, no spaces or punctuation): "
          admin.username = STDIN.gets.strip
          print "\nEnter your password (5-30 chars, no spaces or punctuation): "
          admin.password = STDIN.gets.strip
          break if admin.valid?
          puts "\nThe following errors were encountered:"
          admin.errors.full_messages().each {|msg| puts "  #{msg}"}
          puts
        }
      else
        admin.username = 'admin'
        admin.password = 'password'
      end
      admin.save
      
      # Install some default pages
      pages_file = File.dirname(__FILE__) + "/../../dump/junebug_pages.yml"
      YAML.load_file(pages_file).each {|page_data|Page.create(page_data) } if File.exist?(pages_file)
    end
    def self.down
      drop_table :junebug_pages
      drop_table :junebug_users
      Page.drop_versioned_table
    end
  end

end