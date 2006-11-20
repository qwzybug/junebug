%w(
  rubygems
  test/unit
  active_record
  active_record/fixtures
  active_support/binding_of_caller
  camping
  fileutils
  stringio
  cgi
).each { |lib| require lib }

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")
ActiveRecord::Base.logger = Logger.new("test/test.log")

Test::Unit::TestCase.fixture_path = "test/fixtures/"

class Test::Unit::TestCase #:nodoc:
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false
end

class MockRequest
  def initialize
    @headers = {
      'SERVER_NAME' => 'localhost',
      'PATH_INFO' => '',
      'HTTP_ACCEPT_ENCODING' => 'gzip,deflate',
      'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.1) Gecko/20060214 Camino/1.0',
      'SCRIPT_NAME' => '/',
      'SERVER_PROTOCOL' => 'HTTP/1.1',
      'HTTP_CACHE_CONTROL' => 'max-age=0',
      'HTTP_ACCEPT_LANGUAGE' => 'en,ja;q=0.9,fr;q=0.9,de;q=0.8,es;q=0.7,it;q=0.7,nl;q=0.6,sv;q=0.5,nb;q=0.5,da;q=0.4,fi;q=0.3,pt;q=0.3,zh-Hans;q=0.2,zh-Hant;q=0.1,ko;q=0.1',
      'HTTP_HOST' => 'localhost',
      'REMOTE_ADDR' => '127.0.0.1',
      'SERVER_SOFTWARE' => 'Mongrel 0.3.12.4',
      'HTTP_KEEP_ALIVE' => '300',
      'HTTP_REFERER' => 'http://localhost/',
      'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
      'HTTP_VERSION' => 'HTTP/1.1',
      'REQUEST_URI' => '/',
      'SERVER_PORT' => '80',
      'GATEWAY_INTERFACE' => 'CGI/1.2',
      'HTTP_ACCEPT' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
      'HTTP_CONNECTION' => 'keep-alive',
      'REQUEST_METHOD' => 'GET',
    }
  end

  def set(key, val)
    @headers[key] = val
  end
    
  def to_hash
    @headers
  end

  def [](key)
    @headers[key]
  end

  def []=(key, value)
    @headers[key] = value
  end

  ##
  # Allow getters like this:
  #  o.REQUEST_METHOD

  def method_missing(method_name, *args)
    if @headers.has_key?(method_name.to_s)
      return @headers[method_name.to_s]
    else
      super(method_name, args)
    end
  end

end


module Camping

  class Test < Test::Unit::TestCase
    
    def test_dummy; end
          
    def deny(condition, message='')
      assert !condition, message
    end

    # http://project.ioni.st/post/217#post-217
    #
    #  def test_new_publication
    #    assert_difference(Publication, :count) do
    #      post :create, :publication_title => ...
    #      # ...
    #    end
    #  end
    # 
    # Is the number of items different?
    #
    # Can be used for increment and decrement.
    #
    def assert_difference(object, method = :count, difference = 1)
      initial_value = object.send(method)
      yield
      assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
    end
    def assert_no_difference(object, method, &block)
      assert_difference object, method, 0, &block
    end
    
  end
  
  class FunctionalTest < Test

    def setup
      @class_name_abbr = self.class.name.gsub(/Test$/, '')
      @request = MockRequest.new
    end

    def get(url='/')
      send_request url, {}, 'GET'
    end

    def post(url, post_vars={})
      send_request url, post_vars, 'POST'
    end

    def send_request(url, post_vars, method)
      @request['REQUEST_METHOD'] = method
      @request['SCRIPT_NAME'] = '/' + @class_name_abbr.downcase
      @request['PATH_INFO'] = '/' + url
      @request['REQUEST_URI'] = [@request.SCRIPT_NAME, @request.PATH_INFO].join('')
      
      @request['HTTP_COOKIE'] = @cookies.map {|k,v| "#{k}=#{v}" }.join('; ') if @cookies
      
      @response = eval("#{@class_name_abbr}.run StringIO.new('#{qs_build(post_vars)}'), @request")
      
      @cookies = @response.headers['Set-Cookie'].inject(@cookies||{}) do |res,header|
        data = header.split(';').first
        name, value = data.split('=')
        res[name] = value
        res
      end

      if @response.headers['X-Sendfile']
        @response.body = File.read(@response.headers['X-Sendfile'])
      end      
    end

    def assert_response(status_code)
      case status_code
      when :success
        assert_equal 200, @response.status
      when :redirect
        assert_equal 302, @response.status
      when :error
        assert @response.status >= 500
      else
        assert_equal status_code, @response.status
      end
    end

    def assert_match_body(regex, message=nil)
      assert_match regex, @response.body, message
    end    
    def assert_no_match_body(regex, message=nil)
      assert_no_match regex, @response.body, message
    end
    
    def assert_redirected_to(url, message=nil)
      assert_equal  url, 
                    @response.headers['Location'].path.gsub(%r!/#{@class_name_abbr.downcase}!, ''), 
                    message
    end
    
    def assert_cookie(name, pat, message=nil)
        assert_match pat, @cookies[name], message
    end

    def test_dummy; end

    private

    def qs_build(var_hash)
      var_hash.map do |k, v|
        [Camping.escape(k.to_s), Camping.escape(v.to_s)].join('=')
      end.join('&')
    end

  end

  class UnitTest < Test
    
    def test_dummy; end
  
  end
  
end
