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
    TestCaseExecution.where(:id => object_ids).order(:id)
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
    test_case_execution.project_id = mapping["project_id"].to_i

    begin
      test_case = TestCase.find(row_value(row, "test_case"))
      if test_case and test_case.project_id == test_case_execution.project_id
        test_case_execution.test_case = test_case
      end
    rescue ActiveRecord::RecordNotFound
    end

    begin
      test_plan = TestPlan.find(row_value(row, "test_plan"))
      if test_plan and test_plan.project_id == test_case_execution.project_id
        test_case_execution.test_plan = test_plan
      end
    rescue ActiveRecord::RecordNotFound
    end

    attributes = {
      "comment" => row_value(row, "comment")
    }

    if result = row_value(row, "result")
      if [l(:label_succeed), l(:label_failure)].include?(result)
        attributes["result"] = (result == l(:label_succeed))
      else
        attributes["result"] = nil
      end
    else
      attributes["result"] = nil
    end

    if user_name = row_value(row, "user")
      if found_user = Principal.detect_by_keyword(test_case_execution.ownable_users, user_name)
        attributes["user_id"] = found_user.id
      end
    end

    if execution_date = row_date(row, "execution_date")
      attributes["execution_date"] = execution_date
    end

    if issue_id = row_value(row, "issue")
      begin
        issue = Issue.find(issue_id)
        if issue and issue.project_id == test_case_execution.project_id
          test_case_execution.issue = issue
        end
      rescue ActiveRecord::RecordNotFound
      end
    end

    test_case_execution.send :safe_attributes=, attributes, user

    test_case_execution
  end
end
