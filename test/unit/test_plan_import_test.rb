require File.expand_path("../../test_helper", __FILE__)

class TestPlanImportTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :enabled_modules
  fixtures :test_cases, :test_plans, :test_case_test_plans, :test_case_executions

  include Redmine::I18n

  def setup
    @user = User.current = prepare_authorized_user
    set_language_if_valid 'en'
  end

  def test_authorized
    assert TestPlanImport.authorized?(User.find(1)) # admin
    assert !TestPlanImport.authorized?(User.find(3))

    assert TestPlanImport.authorized?(@user)
  end

  def test_project_should_be_set
    project_id = projects(:projects_003).id

    import = generate_import_with_mapping
    import.user_id = @user.id
    import.mapping["project_id"] = project_id.to_s
    import.save!

    test_plans = new_records(TestPlan, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [project_id, project_id, project_id],
                 test_plans.collect(&:project_id)
  end

  def test_user_association
    associated_user = prepare_authorized_user
    associated_user.update!(firstname: "Test Plan", lastname: "Owner")

    import = generate_import_with_mapping
    import.user_id = @user.id
    import.save!

    test_plans = new_records(TestPlan, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [associated_user.id, associated_user.id, associated_user.id],
                 test_plans.collect(&:user_id)
  end

  def test_user_fallback_to_current_user
    import = generate_import_with_mapping
    import.user_id = @user.id
    import.save!

    test_plans = new_records(TestPlan, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [@user.id, @user.id, @user.id],
                 test_plans.collect(&:user_id)
  end

  def test_run_should_remove_the_file
    import = generate_import_with_mapping
    import.user_id = @user.id

    file_path = import.filepath
    assert File.exist?(file_path)

    import.run
    assert !File.exist?(file_path)
  end

  def test_attach_test_cases
    import = generate_import_with_mapping
    import.user_id = @user.id
    import.save!
    test_plans = new_records(TestPlan, 3) do
      import.run
      assert_successfully_imported(import)
    end
    assert_equal [[101,102,103], [104,105], [106,107]],
                 test_plans.collect{ |test_plan| test_plan.test_cases.collect(&:id).sort }
  end

  class Override < self
    class WithTestPlanId
      def test_with_test_plan_id
        import = generate_import("test_plans.csv")
        import.settings = {
          "separator" => ",",
          "wrapper" => '"',
          "encoding" => "UTF-8",
          "mapping" => {
            "project_id" => "1",

            "test_plan_id" => "0",
            "test_plan" => "1",
            "issue_status" => "2",
            "estimated_bug" => "3",
            "user" => "4",
            "begin_date" => "5",
            "end_date" => "6",
            "test_case_ids" => "7",
          },
        }
        import.save!
        import.user_id = @user.id

        # test plan which is associated with project 1 is updated,
        # then, non associated test plan were imported as new 2 test plans.
        test_plans = new_records(TestPlan, 2) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal ["Test Plan 1", [1, 1], ["Test Plan 2", "Test Plan 3"]],
                     [
                       test_plans(:test_plans_001).name,
                       test_plans.pluck(:project_id),
                       test_plans.pluck(:name),
                     ]
      end
    end

    class WithoutTestPlanId < self
      def test_new_test_plan
        import = generate_import_with_mapping("test_plan1_new.csv")
        import.user_id = @user.id
        import.save!

        # No same test plan, so newly added
        test_plans = new_records(TestPlan, 1) do
          import.run
          assert_successfully_imported(import)
        end
        assert_equal [[1], ["Test Plan 1"]],
                     [
                       test_plans.pluck(:project_id),
                       test_plans.pluck(:name),
                     ]
      end

      def test_override_test_plan
        import = generate_import_with_mapping("test_plan1_override.csv")
        import.user_id = @user.id
        import.save!

        # Override existing test plan
        test_plans = new_records(TestPlan, 0) do
          import.run
          assert_successfully_imported(import)
        end
        test_plan = test_plans(:test_plans_001)
        assert_equal [1, "2022-01-01", "2022-01-01", 100, @user.id, IssueStatus.named("Closed").first.try(:id), 1, [5,6]],
                     [
                       test_plan.id,
                       test_plan.begin_date.strftime("%F"),
                       test_plan.end_date.strftime("%F"),
                       test_plan.estimated_bug,
                       test_plan.user_id,
                       test_plan.issue_status_id,
                       test_plan.project_id,
                       test_plan.test_cases.pluck(:id)
                     ]
      end

      def test_ignored_test_case
        import = generate_import_with_mapping("test_plan1_ignored_test_case.csv")
        import.user_id = @user.id
        import.save!

        # Override existing test plan
        test_plans = new_records(TestPlan, 0) do
          import.run
          assert_successfully_imported(import)
        end
        test_plan = test_plans(:test_plans_001)
        # test case 1 belongs to project 3, so it will be ignored.
        assert_equal [1, 1, []],
                     [
                       test_plan.id,
                       test_plan.project_id,
                       test_plan.test_cases.pluck(:id)
                     ]
      end
    end
  end

  private

  def prepare_authorized_user
    user = User.generate!(firstname: "Test Plan", lastname: "Importer")
    role = Role.generate!
    role.add_permission! :add_test_plans
    role.add_permission! :view_issues
    role.add_permission! :edit_issues
    role.save!
    User.add_to_project(user, Project.find(1), [role])
    User.add_to_project(user, Project.find(3), [role])
    user
  end

  def generate_import(fixture_name="test_plans.csv")
    import = TestPlanImport.new
    import.user_id = 1 # admin
    import.file = uploaded_test_file(fixture_name, "text/csv")
    import.save!
    import
  end

  def generate_import_with_mapping(fixture_name="test_plans.csv")
    import = generate_import(fixture_name)

    import.settings = {
      "separator" => ",",
      "wrapper" => '"',
      "encoding" => "UTF-8",
      "mapping" => {
        "project_id" => "1",

        "test_plan" => "1",
        "issue_status" => "2",
        "estimated_bug" => "3",
        "user" => "4",
        "begin_date" => "5",
        "end_date" => "6",
        "test_case_ids" => "7",
      },
    }
    import.save!
    import
  end
end
