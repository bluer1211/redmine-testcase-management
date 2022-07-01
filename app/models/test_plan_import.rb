class TestPlanImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_plan" => "field_test_plan",
    "issue_status" => "field_issue_status",
    "estimated_bug" => "field_estimated_bug",
    "user" => "field_user",
    "begin_date" => "field_begin_date",
    "end_date" => "field_end_date",
    "test_case_ids" => "field_test_case_ids",
  }

  def self.menu_item
    :test_plans
  end

  def self.authorized?(user)
    user.allowed_to?(:add_test_plans, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    TestPlan.where(:id => object_ids).order(:id)
  end

  def allowed_target_projects
    Project.allowed_to(user, :add_test_plans)
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
    test_plan = TestPlan.new
    test_plan.user = user
    test_plan.project_id = mapping["project_id"].to_i

    # If test_plan_id is mapped, allow to override existing test plan
    test_plan_id = row_value(row, "test_plan_id")
    if test_plan_id
      found_test_plan = TestPlan.where(id: test_plan_id, project_id: test_plan.project_id).first
      if found_test_plan
        test_plan = found_test_plan
        test_plan.user = user
      end
    else
      name = row_value(row, "test_plan")
      found_test_plan = TestPlan.where(name: name, project_id: test_plan.project_id).first
      if found_test_plan
        test_plan = found_test_plan
        test_plan.user = user
      end
    end

    attributes = {
      "name" => row_value(row, "test_plan"),
    }

    status_name = row_value(row, "issue_status")
    status_id = IssueStatus.named(status_name).first.try(:id)
    attributes["issue_status_id"] = status_id

    if user_name = row_value(row, "user")
      if found_user = Principal.detect_by_keyword(test_plan.ownable_users, user_name)
        attributes["user_id"] = found_user.id
      end
    end

    if estimated_bug = row_value(row, "estimated_bug")
      attributes["estimated_bug"] = estimated_bug
    end
    if begin_date = row_date(row, "begin_date")
      attributes["begin_date"] = begin_date
    end
    if end_date = row_date(row, "end_date")
      attributes["end_date"] = end_date
    end

    test_plan.send :safe_attributes=, attributes, user

    test_case_ids = row_value(row, "test_case_ids")
    if found_test_plan and test_case_ids
      # Clear test cases association (e.g. the value of column (:space:) is treated as nil
      test_plan.test_cases.destroy_all
    end
    if test_case_ids
      test_case_ids.scan(/[1-9][0-9]*/) do |test_case_id|
        begin
          test_case = TestCase.where(id: test_case_id.to_i, project_id: test_plan.project_id).first
          if test_case
            unless test_plan.test_cases and test_plan.test_cases.pluck(:id).include?(test_case.id)
              test_plan.test_cases << test_case
            end
          end
        rescue ActiveRecord::RecordNotFound
        end
      end
    end

    test_plan
  end
end
