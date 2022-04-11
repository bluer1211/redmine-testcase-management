require File.expand_path("../../test_helper", __FILE__)

class TestCaseImportTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :enabled_modules
  fixtures :test_cases

  include Redmine::I18n

  def setup
    User.current = nil
    set_language_if_valid 'en'
  end

  def test_authorized
    assert TestCaseImport.authorized?(User.find(1)) # admin
    assert !TestCaseImport.authorized?(User.find(3))

    user = prepare_authorized_user
    assert TestCaseImport.authorized?(user)
  end

  def test_project_should_be_set
    project_id = projects(:projects_003).id

    import = generate_import_with_mapping
    import.mapping["project_id"] = project_id.to_s
    import.save!

    test_cases = new_records(TestCase, 3) do
      import.run
      sleep 0.1 # wait until all imports are finished
    end
    assert_equal [project_id, project_id, project_id],
                 test_cases.collect(&:project_id)
  end

  def test_user_fallback_to_current_user
    user = prepare_authorized_user
    import = generate_import_with_mapping
    import.user_id = user.id
    import.save!

    test_cases = new_records(TestCase, 3) do
      import.run
      sleep 0.1 # wait until all imports are finished
    end
    assert_equal [user.id, user.id, user.id],
                 test_cases.collect(&:user_id)
  end

  def test_run_should_remove_the_file
    import = generate_import_with_mapping
    file_path = import.filepath
    assert File.exist?(file_path)

    import.run
    assert !File.exist?(file_path)
  end

  private

  def prepare_authorized_user
    user = User.generate!
    role = Role.generate!
    role.add_permission! :import_test_cases
    role.save!
    User.add_to_project(user, Project.find(3), [role])
    user
  end

  def generate_import(fixture_name="test_cases.csv")
    import = TestCaseImport.new
    import.user_id = 1 # admin
    import.file = uploaded_test_file(fixture_name, "text/csv")
    import.save!
    import
  end

  def generate_import_with_mapping(fixture_name="test_cases.csv")
    import = generate_import(fixture_name)

    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "1",

        "name" => "1",
        "environment" => "2",
        "user" => "3",
        "scenario" => "5",
        "expected" => "6",
      },
    }
    import.save!
    import
  end
end
