require 'junebug/ext/diff'


module Junebug::Controllers
  # DRY and besides otherwise you need to escape every \d
  def self.slug(after  = '')
    "/(#{Junebug::Models::Page::PAGE_SLUG})" + after
  end
  
  class Index < R '/'
    def get
      redirect Junebug.startpage
    end
  end

  class Show < R slug, slug('/(\d+)')
    def get page_name, version = nil
      @page = Page.find_by_title(page_name.gsub(/_/,' '))
      if @page.nil?
        logged_in? ? redirect(Edit, page_name, 1) : redirect("/login?return_to=#{CGI::escape('/'+page_name)}")
      else
        @page_title = @page.title
        @version = (version.nil? or version == @page.version.to_s) ? @page : @page.versions.find_by_version(version)
        render :show
      end
    end
  end

  class Edit < R slug('/edit'), slug('/(\d+)/edit') 
    
    def get page_name, version = nil
      redirect("/login?return_to=#{CGI::escape('/'+page_name+'/edit')}") and return unless logged_in?
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find_by_title(page_name_spc)
      if @page.nil?
        @page = Page.new(:title=>page_name_spc, :body=>'')
      else
        # check for version request
        @page = @page.versions.find_by_version(version) unless version.nil? or version == @page.version.to_s
      end
      render :edit
    end
    
    # FIXME: no error checking, also no verify quicksave/readonly rights
    def post page_name
      redirect('/login') and return unless logged_in? # shouldn't be here
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find_by_title(page_name_spc)
      if input.submit == 'cancel'
        @page ? redirect(Show, page_name) : redirect(Junebug.startpage)
      else
        attrs = { :body => input.post_body }
        attrs[:readonly] = input.post_readonly if is_admin?
        if input.submit == 'minor edit'
          current_version = @page.find_version(@page.version)
          current_version.update_attributes(attrs)
          @page.without_revision { @page.update_attributes(attrs) }
          redirect Show, page_name_spc.gsub(/ /,'_') # don't allow pagename changes as minor edits
        else
          attrs[:title] = input.post_title
          if input.submit == 'preview'
            @show_preview = true
            if @page
              @page.attributes = attrs
            else
              @page = Page.new(attrs)
            end
            render :edit
          elsif input.submit == 'save'
            attrs[:user_id] = @state.user.id # don't set this until save
            if @page
              @page.update_attributes(attrs)
            else
              @page = Page.create(attrs)
            end
            redirect Show, input.post_title.gsub(/ /,'_')
          end
        end
      end
    end
  end
  
  class Delete < R slug('/delete')
    def get page_name
      redirect("/login") and return unless logged_in? # shouldn't be here
      Page.find_by_title(page_name.gsub(/_/,' ')).destroy() if is_admin?
      redirect Junebug.startpage
    end
    
  end

  class Revert < R slug('/(\d)/revert')
    def get page_name, version
      redirect("/login") and return unless logged_in? # shouldn't be here
      Page.find_by_title(page_name.gsub(/_/,' ')).revert_to!(version) if is_admin?
      redirect Show, page_name
    end
  end

  class Versions < R slug('/versions')
    def get page_name
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find_by_title(page_name_spc)
      @versions = @page.find_versions(:order => 'version DESC', :include => [:user])
      @page_title = "Version History: #{page_name_spc}"
      render :versions
    end
  end

  class List < R '/all/list'
    def get
      @page_title = "All Pages"
      @pages = Page.find :all, :order => 'title'
      render :list
    end
  end

  class Search
    def post 
      @search_term = input.q
      @page_title = "Search Results for: #{@search_term}"
      @pages = Page.find(:all, :conditions => ["body LIKE ? OR title LIKE ?", "%#{@search_term}%", "%#{@search_term}%" ])
      render :search
    end
  end

  class Backlinks < R slug('/backlinks')
    def get page_name
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find_by_title(page_name_spc)
      @page_title = "Backlinks for: #{page_name_spc}"
      @pages = Page.find(:all, :conditions => ["body LIKE ? OR body LIKE ?", "%[[#{page_name_spc}]]%", "%[[#{page_name_spc}|%"])
      render :backlinks
    end
  end

  class Orphans < R '/all/orphans'
    def get
      @page_title = "Orphan pages"
      @pages = Page.find :all, :order => 'title'
      @pages = @pages.reject do |page|
        linked_pages = Page.find(:all, :conditions => ["body LIKE ? OR body LIKE ?", "%[[#{page.title}]]%", "%[[#{page.title}|%"]).length > 0
      end
      render :orphans
    end
  end

  class Users < R '/all/users'
    def get
      @page_title = "Users"
      #@users = User.find(:all, :order => 'username')
      @users = User.find_by_sql("SELECT users.id, username, role, count(*) AS count FROM junebug_users AS users, junebug_page_versions AS versions WHERE users.id=versions.user_id GROUP BY users.id ORDER BY count DESC")
      render :users
    end
  end

  class Userinfo < R '/userinfo/(\w+)'
    def get username
      @page_title = "User info"
      @user = User.find_by_username(username)
      @versions = Page::Version.find(:all, :conditions => ["user_id = ?", @user.id], :order=>'updated_at desc')
      @groups = Hash.new {|hash,key| hash[key] = []}
      @versions.each { |p|
        @groups[p.updated_at.strftime('%Y-%m-%d')].push(p)
      }
      render :userinfo
    end
  end


  class Recent < R '/all/recent'
    def get
      @page_title = "Recent Changes"
      @pages = Page.find(:all, :order => 'updated_at DESC', :conditions => "updated_at > '#{30.days.ago.strftime("%Y-%m-%d %H:%M:%S")}'")
      render :recent
    end
  end
  
  class Diff < R slug('/(\d+)/(\d+)/diff')
    include HTMLDiff
    def get page_name, v1, v2
      page_name_spc = page_name.gsub(/_/,' ')
      @page_title = "Diff: #{page_name_spc}"
      @page = Page.find_by_title(page_name_spc)    
      @v1 = @page.find_version(v1)
      @v2 = @page.find_version(v2)
      
      #@v1_markup = ( @v1.body ? _markup( @v1.body ) : '' )
      #@v2_markup = ( @v2.body ? _markup( @v2.body ) : '' )
      @v1_markup = @v1.body || ''
      @v2_markup = @v2.body || ''
      
      @difftext = diff( @v1_markup , @v2_markup)
      
      render :diff
    end
  end

  class Feed < R '/all/feed'
    def get
      @headers['Content-Type'] = 'application/xml'
      @skip_layout = true
      render :feed
      #return Junebug::Views.feed
    end
  end

  class Static < R '(/images/.+)', '(/style/.+)', '(/javascripts/.+)'
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg'}
    #PATH = __FILE__[/(.*)\//, 1]
    PATH = ENV['JUNEBUG_ROOT'] || File.expand_path('.')
    
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? '..' # sample test to prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/public#{path}"
      else
        "404 - Invalid path"
      end
    end
  end

  class Login
    def get
      @page_title = "Login/Create Account"
      @return_to = input.return_to
      puts "\nBB" + @return_to.to_s
      puts "input: #{input}"
      render :login
    end

    def post
      @page_title = "Login/Create Account"
      @user = User.find :first, :conditions => ['username = ? AND password = ?', input.username, input.password]
      @return_to = input.return_to
      if @user
        if @user.password == input.password
          @state.user = @user
          input.return_to.blank? ? redirect(Junebug.startpage) : redirect(input.return_to)
          return
        else
          @notice = 'Authentication failed'
        end
      else
        @user = User.create :username=>input.username, :password=>input.password
        if @user.errors.empty?
          @state.user = @user
          input.return_to.blank? ? redirect(Junebug.startpage) : redirect(input.return_to)
          return
        else
          @notice = @user.errors.full_messages[0]
        end
      end
      render :login
    end
  end
   
  class Logout
      def get
        @state.user = nil
        input.return_to.blank? ? redirect(Junebug.startpage) : redirect(input.return_to)
      end
  end
end
