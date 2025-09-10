class TestCaseImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_case_id" => "field_test_case_id",
    "test_case" => "field_test_case",
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
    return @project if @project.present?
    
    # 如果沒有 mapping，使用 project_id
    if mapping.present?
      project_id = mapping["project_id"].to_i
      allowed_target_projects.find_by_id(project_id) || allowed_target_projects.first
    else
      # 使用直接存儲的 project_id
      Project.find_by_id(self.project_id) if self.project_id.present?
    end
  end

  def mappable_custom_fields
    []
  end

  def import_result
    @import_result || {}
  end

  def run
    return false unless parsed?
    
    success_count = 0
    error_count = 0
    
    parsed_data.each_with_index do |row, index|
      begin
        object = build_object(row, index)
        if object.save
          success_count += 1
        else
          error_count += 1
          Rails.logger.error "Import error at row #{index + 1}: #{object.errors.full_messages.join(', ')}"
        end
      rescue => e
        error_count += 1
        Rails.logger.error "Import error at row #{index + 1}: #{e.message}"
      end
    end
    
    @import_result = {
      success_count: success_count,
      error_count: error_count,
      total_count: parsed_data.length
    }
    
    true
  end

  def auto_mapping
    return {} unless headers.present?
    mapping = {}
    
    # 使用 Redmine 的 i18n 翻譯機制來獲取不同語系的欄位名稱
    field_mappings = {
      'test_case_id' => [
        '#', 'id', 
        I18n.t('field_test_case_id', locale: :en),
        I18n.t('field_test_case_id', locale: :'zh-TW'),
        I18n.t('field_test_case_id', locale: :ja)
      ],
      'test_case' => [
        'name', 'test_case',
        I18n.t('field_test_case', locale: :en),
        I18n.t('field_test_case', locale: :'zh-TW'),
        I18n.t('field_test_case', locale: :ja)
      ],
      'user' => [
        'user', 'executor',
        I18n.t('field_user', locale: :en),
        I18n.t('field_user', locale: :'zh-TW'),
        I18n.t('field_user', locale: :ja)
      ],
      'environment' => [
        'environment',
        I18n.t('field_environment', locale: :en),
        I18n.t('field_environment', locale: :'zh-TW'),
        I18n.t('field_environment', locale: :ja)
      ],
      'scenario' => [
        'scenario', 'step',
        I18n.t('field_scenario', locale: :en),
        I18n.t('field_scenario', locale: :'zh-TW'),
        I18n.t('field_scenario', locale: :ja)
      ],
      'expected' => [
        'expected', 'result',
        I18n.t('field_expected', locale: :en),
        I18n.t('field_expected', locale: :'zh-TW'),
        I18n.t('field_expected', locale: :ja)
      ],
      'test_plan' => [
        'test_plan', 'plan',
        I18n.t('field_test_plan', locale: :en),
        I18n.t('field_test_plan', locale: :'zh-TW'),
        I18n.t('field_test_plan', locale: :ja)
      ],
      'issue_status' => [
        'status', 'issue_status',
        I18n.t('field_issue_status', locale: :en),
        I18n.t('field_issue_status', locale: :'zh-TW'),
        I18n.t('field_issue_status', locale: :ja)
      ]
    }
    
    field_mappings.each do |field, possible_names|
      # 優先選擇完全匹配的欄位
      matched_header = headers.find do |header|
        header_clean = header.strip.downcase
        possible_names.compact.any? { |name| header_clean == name.downcase }
      end
      
      # 如果沒有完全匹配，再選擇包含匹配的欄位
      unless matched_header
        matched_header = headers.find do |header|
          header_clean = header.strip.downcase
          possible_names.compact.any? { |name| header_clean.include?(name.downcase) }
        end
      end
      
      mapping[field] = matched_header if matched_header
    end
    mapping
  end

  private

  def build_object(row, item)
    test_case = TestCase.new
    test_case.user = user
    test_case.project_id = project_id
    # 根據 test_case_id 自動判斷是否更新現有測試案例

    found_test_case = nil
    test_case_id = row_value(row, "test_case_id")
    if test_case_id.present? && test_case_id.to_s.strip.present?
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
                        # 如果沒有指定 test_case_id，則不更新現有測試案例
                        nil
                      else
                        # 如果沒有指定 test_case_id，則不更新現有測試案例
                        nil
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

    status_name = row_value(row, "issue_status")
    status_id = IssueStatus.named(status_name).first.try(:id)
    attributes["issue_status_id"] = status_id

    test_case.send :safe_attributes=, attributes, user

    if found_test_plan and found_test_plan.project_id == test_case.project_id
      unless found_test_plan.test_cases.pluck(:id).include?(test_case.id)
        found_test_plan.test_cases << test_case
      end
    end

    test_case
  end
end
