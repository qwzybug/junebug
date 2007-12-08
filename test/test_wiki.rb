require 'rubygems'
require 'mosquito'
require File.dirname(__FILE__) + "/../lib/junebug"

Junebug.create
include Junebug::Models

class TestJunebug < Camping::FunctionalTest

  fixtures :junebug_users, :junebug_pages, :junebug_page_versions
  
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

  def test_unicody_slug
    unic_page = Page.create({ :title => "ВикиСлово", 
                  :body => "Слово сказано",
                  :user_id => 1,
                    })
      
    get '/ВикиСлово'
    assert_response :success
    assert_match_body /Слово сказано/
  end
  
  def test_login_basic
    get '/Welcome_to_Junebug/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FWelcome_to_Junebug%2Fedit'

    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'

    get '/Welcome_to_Junebug/edit'
    assert_response :success
    
    get '/logout'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'

    get '/Welcome_to_Junebug/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FWelcome_to_Junebug%2Fedit'
  end
  
  def test_return_to
    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
    
    get '/logout'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
    
    post '/login', :username => 'admin', :password => 'password', :return_to => "/TestPage7"
    assert_response :redirect
    assert_redirected_to '/TestPage7'

    get '/logout', :return_to => '/TestPage7'
    assert_response :redirect
    assert_redirected_to '/TestPage7'
  end


  def test_required_login
    # existing pages
    get '/Welcome_to_Junebug/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FWelcome_to_Junebug%2Fedit'
    
    get '/Welcome_to_Junebug/1/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FWelcome_to_Junebug%2Fedit'

    get '/Welcome_to_Junebug/delete'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/Welcome_to_Junebug/1/revert'
    assert_response :redirect
    assert_redirected_to '/login'

    # page creation
    get '/NonexistentPage/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FNonexistentPage%2Fedit'
    
    get '/NonexistentPage/1/edit'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FNonexistentPage%2Fedit'

    get '/NonexistentPage/delete'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/NonexistentPage/1/revert'
    assert_response :redirect
    assert_redirected_to '/login'
  end
  
  def test_page_editing
    get '/TestPage1'
    assert_response :redirect
    assert_redirected_to '/login?return_to=%2FTestPage1'
    
    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/Welcome_to_Junebug'
    
    get '/TestPage1/edit'
    assert_response :success

    # create page
    post "/TestPage1/edit", :post_title=>"TestPage1", :post_body=>"test body", :post_readonly=>"0", :submit=>'save'    
    assert_response :redirect
    assert_redirected_to "/TestPage1"
    
    page = Junebug::Models::Page.find_by_title("TestPage1")
    
    assert_equal "TestPage1", page.title
    assert_equal "test body", page.body
    assert_equal 1,           page.user_id
    assert_equal false,       page.readonly
    assert_equal 1,           page.version

    # edit, nochange
    post "/TestPage1/edit", :post_title=>page.title, :post_body=>page.body, :post_readonly=>page.readonly, :submit=>'save'
    assert_response :redirect
    assert_redirected_to "/TestPage1"
    
    page2 = Junebug::Models::Page.find_by_title("TestPage1")
    
    assert_equal "TestPage1", page2.title
    assert_equal "test body", page2.body
    assert_equal 1,           page2.user_id
    assert_equal false,       page2.readonly
    assert_equal 2,           page2.version
    
    # submit edited title and body
    post "/TestPage1/edit", :post_title=>'TestPage1xx', :post_body=>'test body xx', :post_readonly=>"0", :submit=>'save'
    assert_response :redirect
    assert_redirected_to "/TestPage1xx"
    
    page3 = Junebug::Models::Page.find_by_title('TestPage1xx')

    assert_equal "TestPage1xx",  page3.title
    assert_equal "test body xx", page3.body
    assert_equal 1,              page3.user_id
    assert_equal false,          page3.readonly
    assert_equal 3,              page3.version   
    
    # submit minor edit
    post "/TestPage1xx/edit", :post_title=>"TestPage1yy", :post_body=>'test body yy', :post_readonly=>"0", :submit=>'minor edit'
    assert_response :redirect
    assert_redirected_to "/TestPage1xx" # not allowed to change the title in minor edit 
    
    page4 = Junebug::Models::Page.find_by_title('TestPage1xx')

    assert_equal "TestPage1xx",  page4.title
    assert_equal "test body yy", page4.body
    assert_equal 1,              page4.user_id
    assert_equal false,          page4.readonly
    assert_equal 3,              page4.version # version doesn't change
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
    page = create(:title => 'TestPage3')
    assert page.valid?
    
    page = create(:title => 'Test Page3')
    assert page.valid?

    page = create(:title => 'Test-Page3')
    assert page.valid?
    
    page = create(:title => 'test page3')
    assert page.valid?
        
    page = create(:title => 'test3')
    assert page.valid?
    
    page = create(:title => 't')
    assert page.valid?

    page = create(:title => '1')
    assert page.valid?

    page = create(:title => 'вики слово')
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
    page1 = create(:title => 'TestTitle51')
    assert page1.valid?
    assert_equal 'TestTitle51', page1.title
    
    # test strip
    page1 = create(:title => ' TestTitle52 ')
    assert page1.valid?
    assert_equal 'TestTitle52', page1.title

    page1 = create(:title => ' Test Title 53 ')
    assert page1.valid?
    assert_equal 'Test Title 53', page1.title
    
    # test squeeze
    page1 = create(:title => '  Test  Title  54  ')
    assert page1.valid?
    assert_equal 'Test Title 54', page1.title
  end

  def test_basic_update
    # create test page
    page = create(:title => "TestUpdate")
    assert page.valid?
    assert_equal 1, page.version
    
    # update body
    page.body = "New body"
    page.save
    assert page.valid?
    assert_equal "TestUpdate", page.title
    assert_equal "New body", page.body
    assert_equal 2, page.version
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

