class TestCaseImport < Import
  AUTO_MAPPABLE_FIELDS = {
    'name' => 'field_name',
    'user' => 'field_user',
    'environment' => 'field_environment',
    'scenario' => 'field_scenario',
    'expected' => 'field_expected',
  }

  def self.menu_item
    :test_cases
  end

  def self.authorized?(user)
    user.allowed_to?(:import_test_cases, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_test_cases.pluck(:obj_id)
    TestCase.where(:id => object_ids).order(:id)
  end

  def mappable_custom_fields
    []
  end

  private

  def build_object(row, item)
    test_case = TestCase.new
    test_case.user = user
    # TBD
    test_case
  end
end
