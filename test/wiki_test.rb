require File.dirname(__FILE__) + "/../lib/junebug/mosquito"
require File.dirname(__FILE__) + "/../lib/junebug"

Junebug.create
include Junebug::Models

class JunebugTest < Camping::FunctionalTest

  fixtures :junebug_users
  
  def setup
    super
  end
  
  def test_index
    get
    assert_response :redirect
    assert_redirected_to '/JunebugWiki'
  end

  def test_start_page
    get '/JunebugWiki'
    assert_response :success
    assert_match_body %r!title>JunebugWiki</title!
  end

  def test_login
    post '/login', :username => 'admin', :password => 'password'
    assert_response :redirect
    assert_redirected_to '/JunebugWiki'
    
    get '/logout'
    assert_response :redirect
    assert_redirected_to '/JunebugWiki'
  end

  def test_required_login
    get '/JunebugWiki/edit'
    assert_response :redirect
    assert_redirected_to '/login'
    
    get '/JunebugWiki/1/edit'
    assert_response :redirect
    assert_redirected_to '/login'

    post '/JunebugWiki/edit'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/JunebugWiki/delete'
    assert_response :redirect
    assert_redirected_to '/login'

    get '/JunebugWiki/1/revert'
    assert_response :redirect
    assert_redirected_to '/login'
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

class PageTest < Camping::UnitTest

  fixtures :junebug_users, :junebug_pages, :junebug_page_versions
      
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

    page = create(:title => 'test page')
    assert page.valid?

    page = create(:title => 'test_page')
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
    
    page = create(:title => 'page-1')
    deny page.valid?
    assert_not_nil page.errors.on(:title)

    page = create(:title => 'page\'s')
    deny page.valid?
    assert_not_nil page.errors.on(:title)
  end
  
  def test_unique_title
    page1 = create(:title => 'TestTitle')
    assert page1.valid?
    
    # identical
    page2 = create
    deny page2.valid?
    assert_not_nil page2.errors.on(:title)

    # lowercase
    page2 = create(:title => 'testtitle')
    assert page2.valid?

    # create page with underscores
    page1 = create(:title => 'test_title')
    assert page1.valid?

    # different from page with spaces
    page1 = create(:title => 'test title')
    assert page1.valid?
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
    user = create(:username => 'aaaaaa  ', :password =>'aaaaaa  ')
    assert user.valid?
    assert user.username == 'aaaaaa'
    assert user.password == 'aaaaaa'
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

