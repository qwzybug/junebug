# require 'active_record'
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
    has_many :page_versions, :class_name => 'Junebug::Models::Page::Version'

    def username=(text)
      write_attribute(:username, (text ? text.strip.downcase : text) )
    end

    def password=(text)
      write_attribute(:password, (text ? text.strip : text) )
    end

  end

  class Page < Base
    belongs_to :user, :class_name=>"Junebug::Models::User", :foreign_key=>'user_id' # Hack to prevent
    # camping error on initial load
    
    PAGE_TITLE = '[\w0-9A-Za-z -]+' # We need the \w for other UTF chars
    PAGE_SLUG = PAGE_TITLE.gsub(/ /, '_')
    DENY_UNDERSCORES =  /^([^_]+)$/
    PAGE_LINK = /\[\[(#{PAGE_TITLE})[|]?([^\]]*)\]\]/
    
    validates_presence_of :title
    validates_uniqueness_of :title
    validates_format_of :title, :with => /^(#{PAGE_TITLE})$/
    # Underscores have to be checked separately because they are included in \w
    validates_format_of :title, :with => /^(#{DENY_UNDERSCORES})$/
    
    acts_as_versioned
    non_versioned_fields.push 'title'
    
    def title=(text)
      write_attribute(:title, text ? text.strip.squeeze(' ') : text)
    end
    
    def title_url
      title.gsub(/\s/,'_')
    end
  end
  
  class Page::Version < Base
    belongs_to :user, :class_name=>"Junebug::Models::User", :foreign_key=>'user_id' # Hack to prevent camping error on initial load
    belongs_to :page, :class_name=>"Junebug::Models::Page", :foreign_key=>'page_id' # Hack to prevent camping error on initial load
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
      if File.exist?(pages_file)
        puts "Loading fixtures"
        YAML.load_file(pages_file).each {|page_data|Page.create(page_data) }
      else
        puts "Could not find fixtures: #{pages_file}" 
      end
    end
    def self.down
      drop_table :junebug_pages
      drop_table :junebug_users
      Page.drop_versioned_table
    end
  end

end