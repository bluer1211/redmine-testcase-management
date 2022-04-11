class TestCaseExecutionImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_case" => "field_test_case",
    "test_plan" => "field_test_plan",
    "result" => "field_result",
    "user" => "field_user",
    "issue" => "field_issue",
    "comment" => "field_comment",
    "execution_date" => "field_execution_date",
  }

  def self.menu_item
    :test_case_executions
  end

  def self.authorized?(user)
    user.allowed_to?(:import_test_case_executions, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    TestPlan.where(:id => object_ids).order(:id)
  end

  def allowed_target_projects
    Project.allowed_to(user, :import_test_case_executions)
  end

  def project
    project_id = mapping["project_id"].to_i
    allowed_target_projects.find_by_id(project_id) || allowed_target_projects.first
  end

  def mappable_custom_fields
    []
  end

  private

  def build_object(row, item)
    test_case_execution = TestCaseExecution.new
    test_case_execution.user = user
    test_case_execution.test_case = TestCase.find(row_value(row, "test_case"))

    test_plan = TestPlan.find(row_value(row, "test_plan"))
    existing_execution = TestCaseExecution.find_by(test_case: test_case_execution.test_case,
                                                   test_plan: test_plan)
    test_case_execution.test_plan = test_plan unless existing_execution

    attributes = {
      "project_id" => mapping["project_id"],
      "comment" => row_value(row, "comment"),
      "result" => (row_value(row, "comment") == l(:label_succeed)),
    }

    if user_name = row_value(row, "user")
      if found_user = Principal.detect_by_keyword(test_case_execution.ownable_users, user_name)
        attributes["user_id"] = found_user.id
      end
    end

    if execution_date = row_date(row, "execution_date")
      attributes["execution_date"] = execution_date
    end

    test_case_execution.send :safe_attributes=, attributes, user

    if test_cases = row_date(row, "test_cases")
      test_cases.scan(/[1-9][0-9]*/) do |test_case_id|
        begin
          test_case = TestCase.find(test_case_id.to_i)
          test_case_execution.test_cases << test_case if test_case
        rescue ActiveRecord::RecordNotFound
        end
      end
    end

    test_case_execution
  end
end
