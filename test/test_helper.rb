# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

def assert_flash_error(message)
  assert_equal message, flash[:error]
  assert_select "div#flash_error" do |div|
    assert_equal message, div.text
  end
end

def assert_contextual_link(label, path)
  assert_select "div#content div.contextual a:first-child" do |a|
    assert_equal path, a.first.attributes["href"].text
    assert_equal label, a.text
  end
end

def assert_back_to_lists_link(path)
  assert_select "div#content a" do |a|
    assert_equal path, a.first.attributes["href"].text
    assert_equal I18n.t(:label_back_to_lists), a.text
  end
end

def login_with_permissions(project, permissions=[:view_project, :view_issues])
  @role = Role.generate!(:permissions => permissions)
  @role.save!
  @user = User.generate!
  User.add_to_project(@user, project, @role)
  @request.session[:user_id] = @user.id
end

def assert_not_select(selector, options = {})
  assert_select selector,
                options.merge({ count: 0 }),
                "unexpectedly exist something matching to the selector: ${selector}"
end

