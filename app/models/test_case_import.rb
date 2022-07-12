class TestCaseImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_case_id" => "field_test_case_id",
    "test_case" => "field_test_case",
    "test_case_update" => "field_test_case_update",
    "user" => "field_user",
    "environment" => "field_environment",
    "scenario" => "field_scenario",
    "expected" => "field_expected",
    "test_plan" => "field_test_plan"
  }

  def self.menu_item
    :test_cases
  end

  def self.authorized?(user)
    user.allowed_to?(:add_test_cases, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    TestCase.where(:id => object_ids).order(:id)
  end

  def allowed_target_projects
    Project.allowed_to(user, :add_test_cases)
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
    test_case = TestCase.new
    test_case.user = user
    test_case.project_id = mapping["project_id"].to_i
    search_test_case = mapping["test_case_update"].to_i.zero? ? false : true

    found_test_case = nil
    if test_case_id = row_value(row, "test_case_id")
      found_test_case = TestCase.where(id: test_case_id, project_id: test_case.project_id).first
    end

    found_test_plan = nil
    if test_plan = row_value(row, "test_plan")
      found_test_plan = if TestPlan.where(name: test_plan, project_id: test_case.project_id).first
                          TestPlan.where(name: test_plan, project_id: test_case.project_id).first
                        elsif TestPlan.where(id: test_plan, project_id: test_case.project_id).first
                          TestPlan.where(id: test_plan, project_id: test_case.project_id).first
                        end
    end

    # If associated test case exists, allow to override existing test case
    name = row_value(row, "test_case")
    found_test_case = if found_test_case
                        found_test_case
                      elsif found_test_plan
                        if search_test_case
                          found_test_plan.test_cases.where(name: name).first
                        else
                          nil
                        end
                      else
                        if search_test_case
                          TestCase.where(name: name, project_id: test_case.project_id).first
                        else
                          nil
                        end
                      end
    if found_test_case
      test_case = found_test_case
      test_case.user = user
    end

    attributes = {
      "name" => row_value(row, "test_case"),
      "environment" => row_value(row, "environment"),
      "scenario" => row_value(row, "scenario"),
      "expected" => row_value(row, "expected"),
    }

    if user_name = row_value(row, "user")
      if found_user = Principal.detect_by_keyword(test_case.ownable_users, user_name)
        attributes["user_id"] = found_user.id
      end
    end

    test_case.send :safe_attributes=, attributes, user

    if found_test_plan and found_test_plan.project_id == test_case.project_id
      unless found_test_plan.test_cases.pluck(:id).include?(test_case.id)
        found_test_plan.test_cases << test_case
      end
    end

    test_case
  end
end
