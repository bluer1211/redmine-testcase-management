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
  permissions += [:test_cases, :test_plans, :test_case_executions]
  @role = Role.generate!(permissions: permissions.uniq)
  @user = User.generate!(login: "temp_user_#{User.count + 1}", password: "password")
  projects.each do |project|
    User.add_to_project(@user, project, @role)
  end
end

def activate_module_for_projects(projects = Project.all)
  projects.each do |project|
    project.enabled_module_names += ["testcase_management"]
    project.save!
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

def generate_test_cases(count, params={})
  count.times.collect do |index|
    TestCase.create!({
      name: "tc#{index}",
      scenario: "scenario",
      expected: "expected",
      environment: "Debian GNU/Linux",
      project: projects(:projects_001),
      user: users(:users_001),
    }.merge(params))
  end
end

def generate_test_case(params={})
  generate_test_cases(1, params).first
end

def generate_test_plans(count, params={})
  count.times.collect do |index|
    TestPlan.create!({
      name: "tp#{index}",
      project: projects(:projects_001),
      user: users(:users_001),
      issue_status: issue_statuses(:issue_statuses_001),
    }.merge(params))
  end
end

def generate_test_plan(params={})
  generate_test_plans(1, params).first
end

def generate_test_case_executions(count, params={})
  count.times.collect do |index|
    TestCaseExecution.create!({
      comment: "tce#{index}",
      project: projects(:projects_001),
      user: users(:users_001),
      result: true,
      execution_date: "2022-04-21",
    }.merge(params))
  end
end

def generate_test_case_execution(params={})
  generate_test_case_executions(1, params).first
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

def filter_params(project_id, field, operation, values, columns)
  filters = {
    project_id: project_id,
    set_filter: 1,
    f: [field],
    op: {
      "#{field}" => operation
    },
    v: values,
    c: columns
  }
  filters
end
