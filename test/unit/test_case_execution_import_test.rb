require File.expand_path("../../test_helper", __FILE__)

class TestCaseExecutionImportTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :enabled_modules
  fixtures :test_cases, :test_plans, :test_case_executions

  include Redmine::I18n

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  def test_authorized
    assert TestCaseExecutionImport.authorized?(User.find(1)) # admin
    assert !TestCaseExecutionImport.authorized?(User.find(3))

    user = prepare_authorized_user
    assert TestCaseExecutionImport.authorized?(user)
  end

  def test_project_should_be_set
    project_id = projects(:projects_003).id

    import = generate_import_with_mapping
    import.mapping["project_id"] = project_id.to_s
    import.save!

    move_test_cases_to_project(project_id)
    test_case_executions = new_records(TestCaseExecution, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [project_id, project_id, project_id],
                 test_case_executions.collect(&:project_id)
  end

  def test_user_fallback_to_current_user
    user = prepare_authorized_user
    import = generate_import_with_mapping
    import.user_id = user.id
    import.save!

    test_case_executions = new_records(TestCaseExecution, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [user.id, user.id, user.id],
                 test_case_executions.collect(&:user_id)
  end

  def test_run_should_remove_the_file
    import = generate_import_with_mapping
    file_path = import.filepath
    assert File.exist?(file_path)

    import.run
    assert !File.exist?(file_path)
  end

  def test_accept_multiple_test_case_executions
    TestCaseExecution.create!(project_id: 1,
                              test_plan_id: 1,
                              test_case_id: 3,
                              user_id: 1,
                              execution_date: Time.now.strftime("%F"),
                              result: true)
    TestCaseExecution.create!(project_id: 1,
                              test_plan_id: 1,
                              test_case_id: 4,
                              user_id: 1,
                              execution_date: Time.now.strftime("%F"),
                              result: false)
    import = generate_import_with_mapping
    new_records(TestCaseExecution, 3) do
      import.run
      assert_successfully_imported(import)
    end
  end

  private

  def prepare_authorized_user
    user = User.generate!
    role = Role.generate!
    role.add_permission! :import_test_case_executions
    role.save!
    User.add_to_project(user, Project.find(3), [role])
    user
  end

  def generate_import(fixture_name="test_case_executions.csv")
    import = TestCaseExecutionImport.new
    import.user_id = 1 # admin
    import.file = uploaded_test_file(fixture_name, "text/csv")
    import.save!
    import
  end

  def generate_import_with_mapping(fixture_name="test_case_executions.csv")
    move_test_cases_to_project(1)
    import = generate_import(fixture_name)

    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "1",

        "test_plan" => "1",
        "test_case" => "2",
        "result" => "3",
        "user" => "4",
        "execution_date" => "5",
        "comment" => "6",
        "issue" => "7",
      },
    }
    import.save!
    import
  end
end
