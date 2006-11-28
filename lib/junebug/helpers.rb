
module Junebug::Helpers

  def logged_in?
    !@state.user.blank?
  end
  
  def is_admin?
     @state.user && @state.user.role == Junebug::Models::User::ROLE_ADMIN
  end
  
  def last_updated(page)
    from = page.updated_at.to_i
    to = Time.now.to_i
    from = from.to_time if from.respond_to?(:to_time)
    to = to.to_time if to.respond_to?(:to_time)
    distance = (((to - from).abs)/60).round
    case distance
      when 0..1      : return (distance==0) ? 'less than a minute' : '1 minute'
      when 2..45     : "#{distance} minutes"
      when 46..90    : 'about 1 hour'
      when 90..1440  : "about #{(distance.to_f / 60.0).round} hours"
      when 1441..2880: '1 day'
      else             "#{(distance / 1440).round} days"
    end
  end

  def diff_link(page, version=nil)
    version = page if version.nil?
    a 'diff', :href => R(Junebug::Controllers::Diff,page.title_url,version.version-1,version.version)
  end

  def auto_link_urls(text)
    extra_options = ""
    text.gsub(/(<\w+.*?>|[^=!:'"\/]|^)((?:http[s]?:\/\/)|(?:www\.))([^\s<]+\/?)([[:punct:]]|\s|<|$)/) do
      all, a, b, c, d = $&, $1, $2, $3, $4
      if a =~ /<a\s/i # don't replace URL's that are already linked
        all
      else
        text = b + c
        text = yield(text) if block_given?
        %(#{a}<a href="#{b=="www."?"http://www.":b}#{c}"#{extra_options}>#{text}</a>#{d})
      end
    end
  end
  

end