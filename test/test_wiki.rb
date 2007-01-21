require 'rubygems'
require 'mosquito'
require File.dirname(__FILE__) + "/../lib/junebug"

Junebug.create
include Junebug::Models

class TestJunebug < Camping::FunctionalTest

  #fixtures :junebug_users
  def setup
    super
  end
  
  def test_index
    get '/'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
  end

  def test_start_page
    get '/Welcome_to_Junebug'
    assert_response :success
    assert_match_body %r!title>Welcome to Junebug</title!
  end

  def test_login
    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
    
    get '/logout'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
  end

  def test_required_login
    get '/Welcome_to_Junebug/edit'
    assert_response :redirect
    assert_redirected_to '/login'
    
    get '/Welcome_to_Junebug/1/edit'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/Welcome_to_Junebug/delete'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/Welcome_to_Junebug/1/revert'
    assert_response :redirect
    assert_redirected_to '/login'
  end
  
  def test_edit_cycle
    get '/Welcome_to_Junebug/edit'
    assert_response :redirect
    assert_redirected_to '/login'
    
    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
    
    get '/Welcome_to_Junebug/edit'
    assert_response :success

    pagename = "Welcome to Junebug"
    page = Junebug::Models::Page.find_by_title(pagename)
    
    # submit nochange
    post "/#{page.title_url}/edit", :post_title=>page.title, :post_body=>page.body, :post_readonly=>page.readonly, :submit=>'save'
    assert_response :redirect
    assert_redirected_to "/#{page.title_url}"
    page2 = Junebug::Models::Page.find_by_title(page.title)
    assert_equal page.title, page2.title
    assert_equal page.body, page2.body
    assert_equal page.user_id, page2.user_id
    assert_equal page.readonly, page2.readonly
    assert_equal page.version+1, page2.version

    pagename = "Welcome to Junebug"
    page = Junebug::Models::Page.find_by_title(pagename)
    
    # submit edited title and body
    post "/#{page.title_url}/edit", :post_title=>page.title+'2', :post_body=>page.body+'2', :post_readonly=>page.readonly, :submit=>'save'
    assert_response :redirect
    assert_redirected_to "/#{page.title_url+'2'}"
    page2 = Junebug::Models::Page.find_by_title(page.title+'2')
    assert_equal page.title+'2', page2.title
    assert_equal page.body+'2', page2.body
    assert_equal page.user_id, page2.user_id
    assert_equal page.readonly, page2.readonly
    assert_equal page.version+1, page2.version
    
    # set it back
    post "/#{page2.title_url}/edit", :post_title=>page.title, :post_body=>page.body, :post_readonly=>page.readonly, :submit=>'save'

  end


# 
#   def test_comment
#     assert_difference(Comment) {
#       page 'comment', :page_username => 'jim', 
#                       :page_body => 'Nice article.', 
#                       :page_id => 1
#       assert_response :redirect
#       assert_redirected_to '/view/1'
#     }
#   end
# 
end

class TestPage < Camping::UnitTest

  fixtures :junebug_users, :junebug_pages, :junebug_page_versions

  def setup
    super
  end

  def test_create
    page = create
    assert page.valid?
  end

  def test_user_assoc
    page = Page.find :first
    assert_kind_of User, page.user
    assert_equal 1, page.user.id
  end

  def test_destroy
    original_count = Page.count
    Page.destroy 1
    assert_equal original_count - 1, Page.count
  end
  
  def test_valid_title
    page = create(:title => 'TestPage')
    assert page.valid?
    
    page = create(:title => 'Test Page')
    assert page.valid?

    page = create(:title => 'Test-Page')
    assert page.valid?
    
    page = create(:title => 'test page')
    assert page.valid?
        
    page = create(:title => 'test')
    assert page.valid?
    
    page = create(:title => 't')
    assert page.valid?

    page = create(:title => '1')
    assert page.valid?

  end
  
  def test_invalid_title
    page = create(:title => nil)
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => '')
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => ' ')
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => '*')
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => 'page\'s')
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => 'test_title')
    deny page.valid?
    assert_not_nil page.errors.on(:title)
  end
  
  def test_unique_title
    page1 = create(:title => 'TestTitle12')
    assert page1.valid?
    
    # identical
    page2 = create(:title => 'TestTitle12')
    deny page2.valid?
    assert_not_nil page2.errors.on(:title)

    # lowercase
    page2 = create(:title => 'testtitle12')
    assert page2.valid?
  end

  def test_spaces
    page1 = create(:title => 'TestTitle5')
    assert page1.valid?
    assert_equal 'TestTitle5', page1.title
    
    # test strip
    page1 = create(:title => ' TestTitle6 ')
    assert page1.valid?
    assert_equal 'TestTitle6', page1.title

    page1 = create(:title => ' Test Title 7 ')
    assert page1.valid?
    assert_equal 'Test Title 7', page1.title
    
    # test squeeze
    page1 = create(:title => '  Test  Title  8  ')
    assert page1.valid?
    assert_equal 'Test Title 8', page1.title
  end


private

  def create(options={})
    Page.create({ :title => "TestTitle", 
                  :body => "Body",
                  :user_id => 1,
                    }.merge(options))
  end
    
end


class UserTest < Camping::UnitTest

  fixtures :junebug_users

  def test_create
    user = create
    assert user.valid?
  end

  def test_required
    user = create(:username => nil)
    deny user.valid?
    assert_not_nil user.errors.on(:username)
    
    user = create(:password => nil)
    deny user.valid?
    assert_not_nil user.errors.on(:password)
  end

  def test_valid_username
    user = create(:username => 'aa')
    deny user.valid?
    assert_not_nil user.errors.on(:username)

    user = create(:username => 'aaa aaa')
    deny user.valid?
    assert_not_nil user.errors.on(:username)
  end

  def test_valid_password
    user = create(:password => 'aa')
    deny user.valid?
    assert_not_nil user.errors.on(:password)

    user = create(:password => 'aaa aaa')
    deny user.valid?
    assert_not_nil user.errors.on(:password)
  end

  def test_unique
    user = create(:username => 'admin')
    deny user.valid?
    assert_not_nil user.errors.on(:username)

    user = create(:username => 'Admin')
    deny user.valid?
    assert_not_nil user.errors.on(:username)
  end

  def test_spaces
    user = create(:username => 'bbbbbb  ', :password =>'bbbbbb  ')
    # puts user.inspect
    assert user.valid?
    assert user.username == 'bbbbbb'
    assert user.password == 'bbbbbb'
  end
  
  def test_lowercase
    user = create(:username => 'AAaaaa')
    assert user.valid?
    assert user.username == 'aaaaaa'
  end


private
  
  def create(options={})
    User.create({ :username => 'godfrey', 
                  :password => 'password' }.merge(options))
  end
  
end

