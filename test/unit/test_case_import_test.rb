require File.expand_path("../../test_helper", __FILE__)

class TestCaseImportTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :enabled_modules
  fixtures :test_cases, :test_plans, :test_case_test_plans

  include Redmine::I18n

  def setup
    @user = User.current = prepare_authorized_user
    set_language_if_valid 'en'
  end

  def test_authorized
    assert TestCaseImport.authorized?(User.find(1)) # admin
    assert !TestCaseImport.authorized?(User.find(3))

    assert TestCaseImport.authorized?(@user)
  end

  def test_project_should_be_set
    project_id = projects(:projects_003).id

    import = generate_import_with_mapping
    import.user_id = @user.id
    import.mapping["project_id"] = project_id.to_s
    import.save!

    test_cases = new_records(TestCase, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [project_id, project_id, project_id],
                 test_cases.collect(&:project_id)
  end

  def test_user_association
    associated_user = prepare_authorized_user
    associated_user.update!(firstname: "Test Case", lastname: "Owner")

    import = generate_import_with_mapping
    import.user_id = @user.id
    import.save!

    test_cases = new_records(TestCase, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [associated_user.id, associated_user.id, associated_user.id],
                 test_cases.collect(&:user_id)
  end

  def test_user_fallback_to_current_user
    import = generate_import_with_mapping
    import.user_id = @user.id
    import.save!

    test_cases = new_records(TestCase, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [@user.id, @user.id, @user.id],
                 test_cases.collect(&:user_id)
  end

  def test_run_should_remove_the_file
    import = generate_import_with_mapping
    import.user_id = @user.id

    file_path = import.filepath
    assert File.exist?(file_path)

    import.run
    assert !File.exist?(file_path)
  end

  def test_with_test_plan
    import = generate_import("test_cases_with_test_plan.csv")
    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "test_plan" => "0",
        "project_id" => "3",
        "test_case" => "1",
        "environment" => "2",
        "user" => "3",
        "scenario" => "5",
        "expected" => "6",
      },
    }
    import.save!
    import.user_id = @user.id

    test_cases = new_records(TestCase, 3) do
      import.run
      assert_successfully_imported(import)
    end
    # imported to test_plans_002 (with existing 1 child test case)
    related_test_cases = test_plans(:test_plans_002).test_cases.pluck(:id) - [test_cases(:test_cases_001).id]
    assert_equal related_test_cases, test_cases.pluck(:id)
  end

  class Override < self
    class WithTestCaseId < self
      def test_override_existing_test_cases
        import = generate_import_with_test_case_id("test_cases_with_test_plan.csv")
        import.user_id = @user.id
        import.save!

        # Existing test cases and association are updated, No new test cases
        test_cases = new_records(TestCase, 0) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [[1, 2, 3], ["Test Case 1", "Test Case 2", "Test Case 3"],
                      [2, 3], ["Test Case 2", "Test Case 3"]],
                     [
                       test_plans(:test_plans_002).test_cases.pluck(:id),
                       test_plans(:test_plans_002).test_cases.pluck(:name),
                       test_plans(:test_plans_003).test_cases.pluck(:id),
                       test_plans(:test_plans_003).test_cases.pluck(:name)
                     ]
      end
    end

    class WithTestPlan < self
      def test_import_new_test_case
        import = generate_import_with_test_plan("test_case1_new.csv")
        import.user_id = @user.id
        import.save!

        # test case is not matched, then imported as new test case
        test_cases = new_records(TestCase, 1) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [["Test Case 1"], [@user.id], ["Ubuntu"], ["Do this."], ["Done this."],
                      [test_plans(:test_plans_002).id]],
                     [
                       test_cases.pluck(:name),
                       test_cases.pluck(:user_id),
                       test_cases.pluck(:environment),
                       test_cases.pluck(:scenario),
                       test_cases.pluck(:expected),
                       test_cases.collect { |test_case| test_case.test_plan.id }
                     ]
      end

      def test_found_test_plan_id
        import = generate_import_with_test_plan("test_case1_new_found_test_plan_id.csv")
        import.user_id = @user.id
        import.save!

        # test plan is found by id, then imported as new test case
        test_cases = new_records(TestCase, 1) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [["Test Case 1 (No test case execution)"],
                      [@user.id],
                      ["Ubuntu"], ["Do this."], ["Done this."],
                      [test_plans(:test_plans_002).id]],
                     [
                       test_cases.pluck(:name),
                       test_cases.pluck(:user_id),
                       test_cases.pluck(:environment),
                       test_cases.pluck(:scenario),
                       test_cases.pluck(:expected),
                       test_cases.collect { |test_case| test_case.test_plan.id }            
                     ]
      end

      def test_override_test_case
        import = generate_import_with_test_plan("test_case1_override.csv", true)
        import.user_id = @user.id
        import.save!

        # test case matched, then override existing test case
        test_cases = new_records(TestCase, 0) do
          import.run
          assert_successfully_imported(import)
        end
        test_case = test_cases(:test_cases_001)
        assert_equal [1, "Test Case 1 (No test case execution)", @user.id, "Ubuntu", "Do this.", "Done this."],
                     [
                       test_case.id,
                       test_case.name,
                       test_case.user_id,
                       test_case.environment,
                       test_case.scenario,
                       test_case.expected,
                     ]
      end

      def test_not_override_test_case
        import = generate_import_with_test_plan("test_case1_override.csv", false)
        import.user_id = @user.id
        import.save!

        # test case will be matched, but do not override existing test case
        test_cases = new_records(TestCase, 1) do
          import.run
          assert_successfully_imported(import)
        end
        test_case = test_cases.first
        assert_equal ["Test Case 1 (No test case execution)", @user.id, "Ubuntu", "Do this.", "Done this."],
                     [
                       test_case.name,
                       test_case.user_id,
                       test_case.environment,
                       test_case.scenario,
                       test_case.expected,
                     ]
      end

      def test_not_found_test_plan
        import = generate_import_with_test_plan("test_case1_override_not_found_test_plan.csv")
        import.user_id = @user.id
        import.save!

        # test plan is not found, then test case will be added
        test_cases = new_records(TestCase, 1) do
          import.run
          assert_successfully_imported(import)
        end
        test_case = test_cases.first
        assert_equal ["Test Case 1 (No test case execution)", @user.id, "Ubuntu", "Do this.", "Done this."],
                     [
                       test_case.name,
                       test_case.user_id,
                       test_case.environment,
                       test_case.scenario,
                       test_case.expected,
                     ]
      end
    end

    class WithTestCaseUpdate < self
      def test_import_new_test_case
        import = generate_import_with_test_case_update("test_case2.csv", false)
        import.user_id = @user.id
        import.save!

        # As update flag is false, test cases will be imported as separated test case.
        test_cases = new_records(TestCase, 2) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [["Test Case 1"] * 2, [@user.id] * 2, ["Ubuntu"] * 2,
                      ["Do this.", "Do that."],
                      ["Done this.", "Done that."]],
                     [
                       test_cases.pluck(:name),
                       test_cases.pluck(:user_id),
                       test_cases.pluck(:environment),
                       test_cases.pluck(:scenario),
                       test_cases.pluck(:expected)
                     ]
      end

      def test_import_updating_test_case
        import = generate_import_with_test_case_update("test_case2.csv", true)
        import.user_id = @user.id
        import.save!

        # test plan is found by id, then imported as new test case
        test_cases = new_records(TestCase, 1) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [["Test Case 1"], [@user.id], ["Ubuntu"], ["Do that."], ["Done that."]],
                     [
                       test_cases.pluck(:name),
                       test_cases.pluck(:user_id),
                       test_cases.pluck(:environment),
                       test_cases.pluck(:scenario),
                       test_cases.pluck(:expected)
                     ]
      end
    end
  end

  private

  def prepare_authorized_user
    user = User.generate!(firstname: "Test Case", lastname: "Importer")
    role = Role.generate!
    role.add_permission! :add_test_cases
    role.add_permission! :view_issues
    role.add_permission! :edit_issues
    role.save!
    User.add_to_project(user, Project.find(1), [role])
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

  def generate_import_with_test_plan(fixture_name="test_case_with_test_plan.csv", test_case_update=nil)
    import = generate_import(fixture_name)
    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "3",

        "test_plan" => "0",
        "test_case" => "2",
        "environment" => "3",
        "user" => "4",
        "scenario" => "6",
        "expected" => "7",
      },
    }
    unless test_case_update.nil?
      import.settings["mapping"]["test_case_update"] = test_case_update ? 1 : 0
    end
    import.save!
    import
  end

  def generate_import_with_test_case_update(fixture_name="test_case2.csv", test_case_update=true)
    import = generate_import(fixture_name)
    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "3",
        "test_case_update" => test_case_update ? 1 : 0,

        "test_plan" => "0",
        "test_case" => "2",
        "environment" => "3",
        "user" => "4",
        "scenario" => "6",
        "expected" => "7",
      },
    }
    import.save!
    import
  end

  def generate_import_with_test_case_id(fixture_name="test_case_with_test_plan.csv")
    import = generate_import(fixture_name)
    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "3",
        "test_plan" => "0",
        "test_case_id" => "1",
        "test_case" => "2",
        "environment" => "3",
        "user" => "4",
        "scenario" => "5",
        "expected" => "6",
      },
    }
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

        "test_case" => "1",
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
