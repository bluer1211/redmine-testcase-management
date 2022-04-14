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

def generate_user_with_permissions(projects, permissions=[:view_project, :view_issues, :add_issues, :edit_issues, :delete_issues])
  projects = [projects] if projects.is_a?(Project)
  permissions = [permissions] unless permissions.is_a?(Array)
  @role = Role.generate!(permissions: permissions)
  @user = User.generate!(login: "temp_user", password: "password")
  projects.each do |project|
    User.add_to_project(@user, project, @role)
  end
end

def login_with_permissions(projects, permissions)
  generate_user_with_permissions(projects, permissions)
  @request.session[:user_id] = @user.id
end

def assert_not_select(selector, options = {})
  assert_select selector,
                options.merge({ count: 0 }),
                "unexpectedly exist something matching to the selector: ${selector}"
end

def assert_successfully_imported(import)
  failures = []
  import.unsaved_items.each_with_index do |item, index|
    failures << "#{item.position}: #{item.message}"
  end
  assert_equal [], failures
end

def move_test_cases_to_project(project_id)
  TestCaseExecution.all.each do |test_case_execution|
    test_case_execution.update!(project_id: project_id)
  end
  TestCase.all.each do |test_case|
    test_case.update!(project_id: project_id)
  end
  TestPlan.all.each do |test_plan|
    test_plan.update!(project_id: project_id)
  end
end
