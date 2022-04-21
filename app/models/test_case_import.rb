class TestCaseImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "name" => "field_name",
    "user" => "field_user",
    "environment" => "field_environment",
    "scenario" => "field_scenario",
    "expected" => "field_expected",
  }

  def self.menu_item
    :test_cases
  end

  def self.authorized?(user)
    user.allowed_to?(:import_test_cases, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    TestCase.where(:id => object_ids).order(:id)
  end

  def allowed_target_projects
    Project.allowed_to(user, :import_test_cases)
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

    attributes = {
      "name" => row_value(row, "name"),
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

    test_case
  end
end
