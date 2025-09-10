class TestCaseExecutionImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_case_execution_id" => "field_test_case_execution_id",
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
    user.allowed_to?(:add_test_case_executions, nil, :global => true)
  end

  def saved_objects
    object_ids = saved_items.pluck(:obj_id)
    TestCaseExecution.where(:id => object_ids).order(:id)
  end

  def allowed_target_projects
    Project.allowed_to(user, :add_test_case_executions)
  end

  def project
    return @project if @project.present?
    return nil unless mapping.present?
    
    project_id = mapping["project_id"].to_i
    allowed_target_projects.find_by_id(project_id) || allowed_target_projects.first
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
      'test_case_execution_id' => [
        '#', 'id',
        I18n.t('field_test_case_execution_id', locale: :en),
        I18n.t('field_test_case_execution_id', locale: :'zh-TW'),
        I18n.t('field_test_case_execution_id', locale: :ja)
      ],
      'test_case' => [
        'test_case', 'case',
        I18n.t('field_test_case', locale: :en),
        I18n.t('field_test_case', locale: :'zh-TW'),
        I18n.t('field_test_case', locale: :ja)
      ],
      'test_plan' => [
        'test_plan', 'plan',
        I18n.t('field_test_plan', locale: :en),
        I18n.t('field_test_plan', locale: :'zh-TW'),
        I18n.t('field_test_plan', locale: :ja)
      ],
      'result' => [
        'result', 'execution_result',
        I18n.t('field_result', locale: :en),
        I18n.t('field_result', locale: :'zh-TW'),
        I18n.t('field_result', locale: :ja)
      ],
      'user' => [
        'user', 'executor',
        I18n.t('field_user', locale: :en),
        I18n.t('field_user', locale: :'zh-TW'),
        I18n.t('field_user', locale: :ja)
      ],
      'issue' => [
        'issue', 'bug',
        I18n.t('field_issue', locale: :en),
        I18n.t('field_issue', locale: :'zh-TW'),
        I18n.t('field_issue', locale: :ja)
      ],
      'comment' => [
        'comment', 'note',
        I18n.t('field_comment', locale: :en),
        I18n.t('field_comment', locale: :'zh-TW'),
        I18n.t('field_comment', locale: :ja)
      ],
      'execution_date' => [
        'execution_date', 'date',
        I18n.t('field_execution_date', locale: :en),
        I18n.t('field_execution_date', locale: :'zh-TW'),
        I18n.t('field_execution_date', locale: :ja)
      ]
    }
    
    field_mappings.each do |field, possible_names|
      matched_header = headers.find do |header|
        header_clean = header.strip.downcase
        possible_names.compact.any? { |name| header_clean.include?(name.downcase) }
      end
      mapping[field] = matched_header if matched_header
    end
    mapping
  end

  private

  def build_object(row, item)
    test_case_execution = TestCaseExecution.new
    test_case_execution.user = user
    test_case_execution.project_id = mapping["project_id"].to_i

    # If test_case_execution_id is mapped, allow to override existing test case execution
    test_case_execution_id = row_value(row, "test_case_execution_id")
    if test_case_execution_id
      found_test_case_execution = TestCaseExecution.where(id: test_case_execution_id, project_id: test_case_execution.project_id).first
      if found_test_case_execution
        test_case_execution = found_test_case_execution
        test_case_execution.user = user
      end
    end

    begin
      id_or_name = row_value(row, "test_case")
      test_case = if TestCase.where(name: id_or_name, project_id: test_case_execution.project_id).first
                    TestCase.where(name: id_or_name, project_id: test_case_execution.project_id).first
                  elsif TestCase.where(id: id_or_name, project_id: test_case_execution.project_id).first
                    TestCase.where(id: id_or_name, project_id: test_case_execution.project_id).first
                  else
                    nil
                  end
      if test_case
        test_case_execution.test_case = test_case
      end
    rescue ActiveRecord::RecordNotFound
    end

    begin
      id_or_name = row_value(row, "test_plan")
      test_plan = if TestPlan.where(name: id_or_name, project_id: test_case_execution.project_id).first
                    TestPlan.where(name: id_or_name, project_id: test_case_execution.project_id).first
                  elsif TestPlan.where(id: id_or_name, project_id: test_case_execution.project_id).first
                    TestPlan.where(id: id_or_name, project_id: test_case_execution.project_id).first
                  else
                    nil
                  end
      if test_plan
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
