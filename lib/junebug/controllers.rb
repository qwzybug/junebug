require 'junebug/diff'

module Junebug::Controllers
  

  class Index < R '/'
    def get
      redirect Junebug.startpage
    end
  end

  class Show < R '/([\w ]+)', '/([\w ]+)/(\d+)'
    def get page_name, version = nil
      @page_title = page_name
      #redirect(Edit, page_name, 1) and return unless @page = Page.find_by_title(page_name)
      redirect("#{Junebug.config['url']}/#{page_name.gsub(/ /,'+')}/1/edit") and return unless @page = Page.find_by_title(page_name)
      @version = (version.nil? or version == @page.version.to_s) ? @page : @page.versions.find_by_version(version)
      render :show
    end
  end

  class Edit < R '/([\w ]+)/edit', '/([\w ]+)/(\d+)/edit' 
    def get page_name, version = nil
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      @page_title = "Edit #{page_name}"
      @page = Page.find(:first, :conditions=>['title = ?', page_name])
      @page = Page.create(:title => page_name, :user_id=>@state.user.id) unless @page
      @page = @page.versions.find_by_version(version) unless version.nil? or version == @page.version.to_s
      render :edit
    end
    
    def post page_name
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      if input.submit == 'save'
        attrs = { :body => input.post_body, :title => input.post_title, :user_id =>@state.user.id }
        attrs[:readonly] = input.post_readonly if is_admin?
        if Page.find_or_create_by_title(page_name).update_attributes( attrs )
          # redirect Show, input.post_title
          redirect "#{Junebug.config['url']}/#{input.post_title.gsub(/ /,'+')}"
        end
      else
        redirect "#{Junebug.config['url']}/#{page_name.gsub(/ /,'+')}"
      end
    end
  end
  
  class Delete < R '/([\w ]+)/delete'
    def get page_name
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      Page.find_by_title(page_name).destroy() if is_admin?
      redirect Junebug.startpage
    end
    
  end

  class Revert < R '/([\w ]+)/(\d+)/revert'
    def get page_name, version
      redirect("#{Junebug.config['url']}/login") and return unless logged_in?
      Page.find_by_title(page_name).revert_to!(version) if is_admin?
      redirect "#{Junebug.config['url']}/#{page_name.gsub(/ /,'+')}"
    end
  end

  class Versions < R '/([\w ]+)/versions'
    def get page_name
      @page_title = "Version History: #{page_name}"
      @page = Page.find_by_title(page_name)
      @versions = @page.find_versions(:order => 'version DESC', :include => [:user])
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

  class Backlinks < R '/([\w ]+)/backlinks'
    def get page_name
      @page = Page.find_by_title(page_name)
      @page_title = "Backlinks for: #{page_name}"
      @pages = Page.find(:all, :conditions => ["body LIKE ?", "%#{page_name}%"])
      render :backlinks
    end
  end

  class Recent < R '/all/recent'
    def get
      @page_title = "Recent Changes"
      @pages = Page.find(:all, :order => 'updated_at DESC', :conditions => "julianday('now')-julianday(updated_at) < 30.0")
      render :recent
    end
  end
  
  class Diff < R '/([\w ]+)/(\d+)/(\d+)/diff'
    include HTMLDiff
    def get page_name, v1, v2
      @page_title = "Diff: #{page_name}"
      @page = Page.find_by_title(page_name)    
      @v1 = @page.find_version(v1)
      @v2 = @page.find_version(v2)
      
      @v1_markup = ( @v1.body ? _markup( @v1.body ) : '' )
      @v2_markup = ( @v2.body ? _markup( @v2.body ) : '' )
      
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

  class Static < R '/static/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg'}
    #PATH = __FILE__[/(.*)\//, 1]
    PATH = ENV['JUNEBUG_ROOT'] || '.'
    
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path =~ /\.\./ # sample test to prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/static/#{path}"
      else
        "404 - Invalid path"
      end
    end
  end

  class Login
    def get
      @page_title = "Login/Create Account"
      render :login
    end

    def post
      @page_title = "Login/Create Account"
      @user = User.find :first, :conditions => ['username = ? AND password = ?', input.username, input.password]
      if @user
        if @user.password == input.password
          @state.user = @user
          redirect(Junebug.startpage); return
        else
          @notice = 'Authentication failed'
        end
      else
          @user = User.create :username=>input.username, :password=>input.password
          if @user.errors.empty?
            @state.user = @user
            redirect(Junebug.startpage); return
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
        redirect(Junebug.startpage)
      end
  end
end