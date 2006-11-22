require 'redcloth'

module Junebug::Views
  def layout
    html {
      head {
        title @page_title ? @page_title : @page.title
        link :href=>'/static/style/yui/reset.css', :type=>'text/css', :rel=>'stylesheet'
        link :href=>'/static/style/yui/fonts.css', :type=>'text/css', :rel=>'stylesheet'
        link :href=>'/static/style/yui/grids.css', :type=>'text/css', :rel=>'stylesheet'
        link :href=>'/static/style/base.css',      :type=>'text/css', :rel=>'stylesheet'
        link :href=>Junebug.config['feed'], :rel => "alternate", :title => "Recently Updated Pages", :type => "application/atom+xml"
        
      }
      body {
        div :id=>'doc', :class=>'yui-t7' do
          self << yield
        end
      }
    }
  end

  def show
    _header (@version.version == @page.version ? :backlinks : :show), @page.title
    _body {
      _button 'edit', R(Edit, @page.title, @version.version), {:style=>'float: right; margin: 0 0 5px 5px;'} if logged_in? && (@version.version == @page.version && (! @page.readonly || is_admin?))
      _markup @version.body
      _button 'edit', R(Edit, @page.title, @version.version), {:style=>'float: right; margin: 5px 0 0 5px;'} if logged_in? && (@version.version == @page.version && (! @page.readonly || is_admin?)) && (@version.body && @version.body.size > 200)
      br :clear=>'all'
    }
    _footer {
      text "Last edited by <b>#{@version.user.username}</b> on #{@page.updated_at.strftime('%B %d, %Y %I:%M %p')}"
      if @version.version > 1
        text " ("
        a 'diff', :href => R(Diff,@page.title,@version.version-1,@version.version)
        text ")"
      end
      br
      text '<b>[readonly]</b> ' if @page.readonly
      span.actions {
        text "Version #{@version.version} "
        text "(current) " if @version.version == @page.version
        #text 'Other versions: '
        a '«older', :href => R(Show, @page.title, @version.version-1) unless @version.version == 1
        a 'newer»', :href => R(Show, @page.title, @version.version+1) unless @version.version == @page.version
        a 'current', :href => R(Show, @page.title) unless @version.version == @page.version
        a 'versions', :href => R(Versions, @page.title)
      }
    }
    if is_admin?
      div.admin {
        _button 'delete', R(Delete, @page.title), {:onclick=>"return confirm('Sure you want to delete?')"} if @version.version == @page.version
        _button 'revert to', R(Revert, @page.title, @version.version), {:onclick=>"return confirm('Sure you want to revert?')"} if @version.version != @page.version
      }
    end
  end

  def edit
    _header :show, @page.title
    _body {
      div.formbox {
        form :method => 'post', :action => R(Edit, @page.title) do
          p { 
            label 'Page Title'
            br
            input :value => @page.title, :name => 'post_title', :size => 30, 
                  :type => 'text'
            small " word characters [0-9A-Za-z_] and spaces only"
          }
          p {
            label 'Page Content'
            br
            textarea @page.body, :name => 'post_body', :rows => 17, :cols => 80
          }
          if is_admin?
            opts = { :type => 'checkbox', :value=>'1', :name => 'post_readonly' }
            opts[:checked] = 1 if @page.readonly
            input opts
            text " Readonly "
          end
          if @page.user_id == @state.user.id
            input :type=>'checkbox', :value=>'1', :name=>'quicksave'
            text " Quicksave "
          end
          br
          input :type => 'submit', :name=>'submit', :value=>'cancel', :class=>'button', :style=>'float: right;'
          input :type => 'submit', :name=>'submit', :value=>'save', :class=>'button', :style=>'float: right;'
        end
        a 'syntax help', :href => 'http://hobix.com/textile/', :target=>'_blank'
        br :clear=>'all'
      }
    }
    _footer { '' }
  end

  def versions
    _header :show, @page.title
    _body {
      h1 @page_title
      ul {
        @versions.each_with_index do |page,i|
          li {
            a "version #{page.version}", :href => R(Show, @page.title, page.version)
            if page.version > 1
              text ' ('
              a 'diff', :href => R(Diff, @page.title, page.version-1, page.version)
              text ')'
            end
            text' - created '
            text last_updated(page)
            text ' ago by '
            strong page.user.username
            text ' (current)' if @page.version == page.version
          }
        end
      }
    }
    _footer { '' }
  end

  def backlinks
    _header :show, @page.title
    _body {
      h1 "Backlinks to #{@page.title}"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title) } }
      }
    }
    _footer { '' }
  end

  def list
    _header :static, @page_title
    _body {
      h1 "All Wiki Pages"
      ul {
        @pages.each { |p| li{ a p.title, :href => R(Show, p.title) } }
      }
    }
    _footer { '' }
  end


  def recent
    _header :static, @page_title
    _body {
      h1 "Updates in the last 30 days"
      page = @pages.shift 
      while page
        yday = page.updated_at.yday
        h2 page.updated_at.strftime('%B %d, %Y')
        ul {
          loop do
            li {
              a page.title, :href => R(Show, page.title)
              text ' ('
              a 'versions', :href => R(Versions, page.title)
              text ') '
              span page.updated_at.strftime('%I:%M %p')
            }
            page = @pages.shift
            break unless page && (page.updated_at.yday == yday)
          end
        }
      end
    }
    _footer { '' }
  end
  
  def diff
    _header :show, @page.title
    _body {
      text 'Comparing '
      span "version #{@v2.version}", :style=>"background-color: #cfc; padding: 1px 4px;"
      text ' and '
      span "version #{@v1.version}", :style=>"background-color: #ddd; padding: 1px 4px;"
      text ' '
      a "back", :href => R(Show, @page.title)
      br
      br
      div.diff {
        text @difftext
      }
    }
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
    txt.gsub!(Junebug::Models::Page::PAGE_LINK) do
      page = title = $1
      title = $2 unless $2.empty?
      #page = page.gsub /\W/, '_'
      if Junebug::Models::Page.find(:all, :select => 'title').collect { |p| p.title }.include?(page)
        %Q{<a href="#{self/R(Show, page)}">#{title}</a>}
      else
        %Q{<span>#{title}<a href="#{self/R(Edit, page, 1)}">?</a></span>}
      end
    end
    text RedCloth.new(auto_link_urls(txt), [ ]).to_html
  end

  def _header type, page_title
    div :id=>'hd' do
      span :id=>'userlinks', :style=>'float: right;' do
        logged_in? ? (text "Welcome, #{@state.user.username} - " ; a('sign out', :href=>"#{R(Logout)}?return_to=#{@env['REQUEST_URI']}")) : a('sign in', :href=> "#{R(Login)}?return_to=#{@env['REQUEST_URI']}")
      end
      if type == :static
        h1 page_title
      elsif type == :backlinks
        h1 { a page_title, :href => R(Backlinks, page_title) }
      else
        h1 { a page_title, :href => R(Show, page_title) }
      end
      span {
        a 'Home',  :href => R(Show, Junebug.config['startpage'])
        text ' | '
        a 'RecentChanges', :href => R(Recent)
        text ' | '
        a 'All Pages', :href => R(List)
        text ' | '
        a 'Help', :href => R(Show, "JunebugHelp") 
      }
    end
  end

  def _body
    div :id=>'bd' do
      div :id=>'yui-main' do
        div :class=>'yui-b' do
          div.content do
            yield
          end
        end
      end
    end
  end

  def _footer
    div :id=>'ft' do
      span :style=>'float: right;' do
        text 'Powered by '
        a 'JunebugWiki', :href => 'http://www.junebugwiki.com/'
        text " <small>v#{Junebug::VERSION::STRING}</small> "
        a :href => Junebug.config['feed'] do
          img :src => '/static/images/feed-icon-14x14.png'
        end
      end
      yield
      br :clear=>'all'
    end
  end

  def self.feed
    xml = Builder::XmlMarkup.new(:indent => 2)

    xml.instruct!
    xml.feed "xmlns"=>"http://www.w3.org/2005/Atom" do

      xml.title "Recently Updated Wiki Pages"
      xml.id Junebug.config['url'] + '/'
      xml.link "rel" => "self", "href" => Junebug.config['feed']

      pages = Junebug::Models::Page.find(:all, :order => 'updated_at DESC', :limit => 20)
      xml.updated pages.first.updated_at.xmlschema

      pages.each do |page|
        xml.entry do
          xml.id Junebug.config['url'] + '/' + page.title
          xml.title page.title
          xml.author { xml.name page.user.username }
          xml.updated page.updated_at.xmlschema
          xml.link "rel" => "alternate", "href" => Junebug.config['url'] + '/' + page.title
          xml.summary "#{page.title}"
          xml.content 'type' => 'html' do 
            xml.text! page.body.gsub("\n", '<br/>').gsub("\r", '') 
          end
        end
      end   
    end
  end

end
