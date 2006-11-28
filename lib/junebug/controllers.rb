require 'junebug/ext/diff'

module Junebug::Controllers
  

  class Index < R '/'
    def get
      redirect Junebug.startpage
    end
  end

  class Show < R '/([0-9A-Za-z_-]+)', '/([0-9A-Za-z_-]+)/(\d+)'
    def get page_name, version = nil
      #redirect(Edit, page_name, 1) and return unless @page = Page.find_by_title(page_name)
      redirect("#{Junebug.config['url']}/#{page_name.gsub(/ /,'+')}/1/edit") and return unless @page = Page.find_by_title(page_name.gsub(/_/,' '))
      @page_title = @page.title
      @version = (version.nil? or version == @page.version.to_s) ? @page : @page.versions.find_by_version(version)
      render :show
    end
  end

  class Edit < R '/([0-9A-Za-z_-]+)/edit', '/([0-9A-Za-z_-]+)/(\d+)/edit' 
    def get page_name, version = nil
      redirect("#{Junebug.config['url']}/login?return_to=#{CGI::escape(@env['REQUEST_URI'])}") and return unless logged_in?
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find(:first, :conditions=>['title = ?', page_name_spc])
      @page = Page.create(:title => page_name_spc, :user_id=>@state.user.id) unless @page
      @page = @page.versions.find_by_version(version) unless version.nil? or version == @page.version.to_s
      @page_title = "Editing: #{page_name_spc}"
      render :edit
    end
    
    # FIXME: no error checking, also no verify quicksave/readonly rights
    def post page_name
      redirect("#{Junebug.config['url']}/login?return_to=#{CGI::escape(@env['REQUEST_URI'])}") and return unless logged_in?
      page_name_spc = page_name.gsub(/_/,' ')
      if input.submit == 'save'
        if ! input.quicksave
          attrs = { :body => input.post_body, :title => input.post_title, :user_id =>@state.user.id }
          attrs[:readonly] = input.post_readonly if is_admin?
          Page.find_or_create_by_title(page_name_spc).update_attributes(attrs)
        else
          attrs = { :body => input.post_body }
          attrs[:readonly] = input.post_readonly if is_admin?
          page = Page.find_by_title(page_name_spc)
          current_version = page.find_version(page.version)
          current_version.update_attributes(attrs)
          page.without_revision { page.update_attributes(attrs) }
        end
        # redirect Show, input.post_title
        redirect "#{Junebug.config['url']}/#{input.post_title.gsub(/ /,'_')}"
      else # cancel
        redirect "#{Junebug.config['url']}/#{page_name}"
      end
    end
  end
  
  class Delete < R '/([0-9A-Za-z_-]+)/delete'
    def get page_name
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      Page.find_by_title(page_name.gsub(/_/,' ')).destroy() if is_admin?
      redirect Junebug.startpage
    end
    
  end

  class Revert < R '/([0-9A-Za-z_-]+)/(\d+)/revert'
    def get page_name, version
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      Page.find_by_title(page_name.gsub(/_/,' ')).revert_to!(version) if is_admin?
      redirect "#{Junebug.config['url']}/#{page_name}"
    end
  end

  class Versions < R '/([0-9A-Za-z_-]+)/versions'
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

  class Backlinks < R '/([0-9A-Za-z_-]+)/backlinks'
    def get page_name
      page_name_spc = page_name.gsub(/_/,' ')
      @page = Page.find_by_title(page_name_spc)
      @page_title = "Backlinks for: #{page_name_spc}"
      @pages = Page.find(:all, :conditions => ["body LIKE ?", "%#{page_name_spc}%"])
      render :backlinks
    end
  end

  class Recent < R '/all/recent'
    def get
      @page_title = "Recent Changes"
      @pages = Page.find(:all, :order => 'updated_at DESC', :conditions => "updated_at > '#{30.days.ago.strftime("%Y-%m-%d %H:%M:%S")}'")
      render :recent
    end
  end
  
  class Diff < R '/([0-9A-Za-z_-]+)/(\d+)/(\d+)/diff'
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
      return Junebug::Views.feed
    end
  end

  class Static < R '(/images/.+)', '(/style/.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg'}
    #PATH = __FILE__[/(.*)\//, 1]
    PATH = ENV['JUNEBUG_ROOT'] || '.'
    
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path =~ /\.\./ # sample test to prevent directory traversal attacks
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
      render :login
    end

    def post
      @page_title = "Login/Create Account"
      @user = User.find :first, :conditions => ['username = ? AND password = ?', input.username, input.password]
      @return_to = input.return_to
      if @user
        if @user.password == input.password
          @state.user = @user
          input.return_to.blank? ? redirect(Junebug.startpage) : redirect(Junebug.config['url'] + input.return_to)
          return
        else
          @notice = 'Authentication failed'
        end
      else
        @user = User.create :username=>input.username, :password=>input.password
        if @user.errors.empty?
          @state.user = @user
          input.return_to.blank? ? redirect(Junebug.startpage) : redirect(Junebug.config['url'] + input.return_to)
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
        input.return_to.blank? ? redirect(Junebug.startpage) : redirect(Junebug.config['url'] + input.return_to)
      end
  end
end
