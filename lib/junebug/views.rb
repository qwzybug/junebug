require 'junebug/ext/redcloth'

module Junebug::Views
  
  def layout
    if @skip_layout
      yield
    else
      html {
        head {
          title @page_title ? @page_title : @page.title
          link :href=>'/style/yui/reset.css', :type=>'text/css', :rel=>'stylesheet'
          link :href=>'/style/yui/fonts.css', :type=>'text/css', :rel=>'stylesheet'
          link :href=>'/style/base.css',      :type=>'text/css', :rel=>'stylesheet'
          link :href=>Junebug.config['feedurl'], :rel => "alternate", :title => "Recently Updated Pages", :type => "application/atom+xml"
        }
        body {
          div :id=>'doc' do
            self << yield
          end
        }
      }
    end
  end


  def show
    _header (@version.version == @page.version ? :backlinks : :show)
    _body do
      _button 'edit', R(Edit, @page.title_url, @version.version), {:style=>'float: right; margin: 0 0 5px 5px;', :accesskey => 'e'} if (@version.version == @page.version && (! @page.readonly || is_admin?))
      h1 @page.title
      _markup @version.body
      _button 'edit', R(Edit, @page.title_url, @version.version), {:style=>'float: right; margin: 5px 0 0 5px;'} if (@version.version == @page.version && (! @page.readonly || is_admin?)) && (@version.body && @version.body.size > 200)
      br :clear=>'all'
    end
    _footer {
      text "Page last edited by <b>#{@version.user.username}</b> on #{@page.updated_at.strftime('%B %d, %Y %I:%M %p')}"
      text " (#{diff_link(@page, @version)}) " if @version.version > 1
      br
      text '<b>[readonly]</b> ' if @page.readonly
      span.actions {
        text "Version #{@version.version} "
        text "(current) " if @version.version == @page.version
        #text 'Other versions: '
        a '«older', :href => R(Show, @page.title_url, @version.version-1) unless @version.version == 1
        a 'newer»', :href => R(Show, @page.title_url, @version.version+1) unless @version.version == @page.version
        a 'current', :href => R(Show, @page.title_url) unless @version.version == @page.version
        a 'versions', :href => R(Versions, @page.title_url)
      }
    }
    if is_admin?
      div.admin {
        _button 'delete', R(Delete, @page.title_url), {:onclick=>"return confirm('Sure you want to delete?')"} if @version.version == @page.version
        _button 'revert to', R(Revert, @page.title_url, @version.version), {:onclick=>"return confirm('Sure you want to revert?')"} if @version.version != @page.version
      }
    end
  end


  def edit
    _header :show
    _body do
      h1 @page_title
      div.formbox {
        form :method => 'post', :action => R(Edit, @page.title_url) do
          p { 
            label 'Page Title'
            br
            input :value => @page.title, :name => 'post_title', :size => 30, 
                  :type => 'text'
            small " word characters (0-9A-Za-z), dashes, and spaces only"
          }
          p {
            a 'syntax help', :href => 'http://hobix.com/textile/', :target=>'_blank', :style => 'float: right;'
            label 'Page Content '
            br
            textarea @page.body, :name => 'post_body', :rows => 17, :cols => 80
          }
          input :type => 'submit', :name=>'submit', :value=>'cancel', :class=>'button', :style=>'float: right;'
          input :type => 'submit', :name=>'submit', :value=>'save', :class=>'button', :style=>'float: right;', :accesskey => 's'
          if is_admin?
            opts = { :type => 'checkbox', :value=>'1', :name => 'post_readonly' }
            opts[:checked] = 1 if @page.readonly
            input opts
            text " Readonly "
            br
          end
          if @page.user_id == @state.user.id
            input :type=>'checkbox', :value=>'1', :name=>'quicksave'
            text " Minor edit (don't increment version) "
          end

        end
        br :clear=>'all'
      }
    end
    _footer { '' }
  end


  def versions
    _header :show
    _body do
      h1 @page_title
      ul {
        @versions.each_with_index do |page,i|
          li {
            a "version #{page.version}", :href => R(Show, @page.title_url, page.version)
            text " (#{diff_link(@page, page)}) " if page.version > 1
            text' - created '
            text last_updated(page)
            text ' ago by '
            strong page.user.username
            text ' (current)' if @page.version == page.version
          }
        end
      }
    end
    _footer { '' }
  end


  def search
    _header :show
    _body do
      h1 "Search results"

      form :action => R(Search), :method => 'post' do
        input :name => 'q', :type => 'text', :value=>@search_term, :accesskey => 's' 
        input :type => 'submit', :name => 'search', :value => 'Search',
          :style=>'margin: 0 0 5px 5px;'
      end

      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title_url) } }
      }
    end
    _footer { '' }
  end


  def backlinks
    _header :show
    _body do
      h1 "Backlinks to #{@page.title}"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title) } }
      }
    end
    _footer { '' }
  end


  def list
    _header :static
    _body do
      h1 "All wiki pages"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title_url) } }
      }
    end
    _footer { '' }
  end


  def recent
    _header :static
    _body do
      h1 "Updates in the last 30 days"
      page = @pages.shift 
      while page
        yday = page.updated_at.yday
        h2 page.updated_at.strftime('%B %d, %Y')
        ul {
          loop do
            li {
              a page.title, :href => R(Show, page.title_url)
              text ' ('
              a 'versions', :href => R(Versions, page.title_url)
              text ",#{diff_link(page)}" if page.version > 1
              text ') '
              span page.updated_at.strftime('%I:%M %p')
            }
            page = @pages.shift
            break unless page && (page.updated_at.yday == yday)
          end
        }
      end
    end
    _footer { '' }
  end
  
  def diff
    _header :show
    _body do
      text 'Comparing '
      span "version #{@v2.version}", :style=>"background-color: #cfc; padding: 1px 4px;"
      text ' and '
      span "version #{@v1.version}", :style=>"background-color: #ddd; padding: 1px 4px;"
      text ' '
      a "back", :href => R(Show, @page.title_url)
      br
      br
      pre.diff {
        text @difftext
      }
    end
    _footer { '' }
  end
  
  def login
    div.login {
      h1 @page_title
      p.notice { @notice } if @notice
      form :action => R(Login), :method => 'post' do
        label 'Username', :for => 'username'; br
        input :name => 'username', :type => 'text', :value=>( @user ? @user.username : '') ; br

        label 'Password', :for => 'password'; br
        input :name => 'password', :type => 'password'; br
        
        input :name => 'return_to', :type => 'hidden', :value=>@return_to

        input :type => 'submit', :name => 'login', :value => 'Login'
      end
    }
  end

  def _button(text, href, options={})
    form :method=>:get, :action=>href do
      opts = {:type=>'submit', :name=>'submit', :value=>text}.merge(options)
      input.button opts
    end
  end

  def _markup txt
    return '' if txt.blank?
    titles = Junebug::Models::Page.find(:all, :select => 'title').collect { |p| p.title }
    txt.gsub!(Junebug::Models::Page::PAGE_LINK) do
      page = title = $1
      title = $2 unless $2.empty?
      page_url = page.gsub(/ /, '_')
      if titles.include?(page)
        %Q{<a href="#{self/R(Show, page_url)}">#{title}</a>}
      else
        %Q{<span>#{title}<a href="#{self/R(Edit, page_url, 1)}">?</a></span>}
      end
    end
    #text RedCloth.new(auto_link_urls(txt), [ ]).to_html
    text RedCloth.new(txt, [ ]).to_html
  end

  def _header type
    div :id=>'hd' do
      
      span :id=>'userlinks' do
        if logged_in?
          text "Hi, #{@state.user.username} - "
          a 'sign out', :href=>"#{R(Logout)}?return_to=#{@env['REQUEST_URI']}"
        else
          a 'sign in', :href=> "#{R(Login)}?return_to=#{@env['REQUEST_URI']}"
        end
      end

      span :id=>'search' do
        # text 'Search: '
        form :action => R(Search), :method => 'post' do
          input :name => 'q', :type => 'text', :value=>(''), :accesskey => 's' 
          #input :type => 'submit', :name => 'search', :value => 'Search',
          #  :style=>'margin: 0 0 5px 5px;'
        end
      end
   
      span :id=>'navlinks' do
        a 'Home',  :href => R(Show, Junebug.config['startpage'])
        text ' | '
        a 'Recent Changes', :href => R(Recent)
        text ' | '
        a 'All Pages', :href => R(List)
        text ' | '
        a 'Help', :href => R(Show, "Junebug_help") 
      end
      
      br :clear => 'all'
      
      # if type == :static
      #   h1 page_title
      # elsif type == :backlinks
      #   h1 { a page_title, :href => R(Backlinks, page_title) }
      # else
      #   h1 { a page_title, :href => R(Show, page_title) }
      # end
      
    end
  end

  def _body
    div :id=>'bd' do
      div.content do
        yield
      end
    end
  end

  def _footer
    div :id=>'ft' do
      span :style=>'float: right;' do
        text 'Powered by '
        a 'JunebugWiki', :href => 'http://www.junebugwiki.com/'
        text " <small>v#{Junebug::VERSION::STRING}</small> "
        a :href => Junebug.config['feedurl'] do
          img :src => '/images/feed-icon-14x14.png'
        end
      end
      yield
      br :clear=>'all'
    end
  end

  def feed
    site_url = Junebug.config['siteurl'] || "http://#{Junebug.config['host']}:#{Junebug.config['port']}"
    site_domain = site_url.gsub(/^http:\/\//, '').gsub(/:/,'_')
    feed_url = site_url + R(Feed)

    xml = Builder::XmlMarkup.new(:target => self, :indent => 2)

    xml.instruct!
    xml.feed "xmlns"=>"http://www.w3.org/2005/Atom" do

      xml.title Junebug.config['feedtitle'] || "Wiki Updates"
      xml.id site_url
      xml.link "rel" => "self", "href" => feed_url

      pages = Junebug::Models::Page.find(:all, :order => 'updated_at DESC', :limit => 20)
      xml.updated pages.first.updated_at.xmlschema
      
      pages.each do |page|
        atom_id = "tag:#{site_domain},#{page.created_at.strftime("%Y-%m-%d")}:page/#{page.id}/#{page.version}"
        xml.entry do
          xml.id atom_id
          xml.title page.title
          xml.updated page.updated_at.xmlschema
          
          xml.author { xml.name page.user.username }
          xml.link "rel" => "alternate", "href" => site_url + R(Show, page.title_url)
          xml.summary :type=>'html' do
            xml.text! %|<a href="#{site_url + R(Show, page.title_url)}">#{page.title}</a> updated by #{page.user.username}|
            xml.text! %| (<a href="#{site_url + R(Diff,page.title_url,page.version-1,page.version)}">diff</a>)| if page.version > 1
            xml.text! "\n"
          end
          # xml.content do 
          #   xml.text! CGI::escapeHTML(page.body)+"\n"
          # end
        end
      end   
    end
  end

end
