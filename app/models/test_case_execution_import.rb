class TestCaseExecutionImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_case" => "field_test_case",
    "test_plan" => "field_test_plan",
    "user" => "field_user",
    "result" => "field_result",
    "comment" => "field_comment",
    "execution_date" => "field_execution_date",
    "issue" => "field_issue"
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
    # 修復: 確保 user 存在，如果沒有則使用 User.current
    current_user = user || User.current
    if current_user && !current_user.is_a?(AnonymousUser)
      Project.allowed_to(current_user, :add_test_case_executions)
    else
      # 如果沒有有效用戶，返回所有專案（僅用於調試）
      Project.all
    end
  end

  def project
    # 修復: 優先使用 settings 中的 project_id，然後是 mapping
    project_id = nil
    
    # 優先從 settings 獲取
    if settings && settings['project_id']
      project_id = settings['project_id']
    end
    
    # 如果沒有，從 mapping 獲取
    if project_id.nil? && mapping && mapping["project_id"]
      project_id = mapping["project_id"]
    end
    
    # 如果還是沒有，使用自身的 project_id
    if project_id.nil? && self.project_id
      project_id = self.project_id
    end
    
    # 嘗試查找專案
    if project_id
      # 嘗試按 ID 或標識符查找
      found_project = if project_id.to_s.match?(/^\d+$/)
                        Project.find_by(id: project_id.to_i)
                      else
                        Project.find_by(identifier: project_id.to_s)
                      end
      
      # 檢查專案是否在允許的專案列表中
      if found_project && allowed_target_projects.include?(found_project)
        return found_project
      end
    end
    
    # 回退到第一個可用專案
    allowed_target_projects.first
  end

  # 新增: 確保專案上下文正確設置
  def ensure_project_context
    if self.project_id.nil? || self.project_id == 0
      # 從 settings 中獲取 project_id
      if settings && settings['project_id']
        project_id = settings['project_id']
        # 嘗試按 ID 或標識符查找
        found_project = if project_id.to_s.match?(/^\d+$/)
                          Project.find_by(id: project_id.to_i)
                        else
                          Project.find_by(identifier: project_id.to_s)
                        end
        if found_project
          self.project_id = found_project.id
        end
      end
    end
  end

  # 新增: 在保存前確保專案上下文
  before_save :ensure_project_context

  def mappable_custom_fields
    []
  end

  private

  def build_object(row, item)
    test_case_execution = TestCaseExecution.new
    test_case_execution.user = user || User.current
    test_case_execution.project_id = mapping["project_id"].to_i

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

    test_case_execution.send :safe_attributes=, attributes, user || User.current

    test_case_execution
  end
end
