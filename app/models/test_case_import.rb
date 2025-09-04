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
    # 修復: 確保 user 存在，如果沒有則使用 User.current
    current_user = user || User.current
    if current_user && !current_user.is_a?(AnonymousUser)
      Project.allowed_to(current_user, :add_test_cases)
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
    test_case = TestCase.new
    test_case.user = user || User.current
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
      test_case.user = user || User.current
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

    test_case.send :safe_attributes=, attributes, user || User.current

    if found_test_plan and found_test_plan.project_id == test_case.project_id
      unless found_test_plan.test_cases.pluck(:id).include?(test_case.id)
        found_test_plan.test_cases << test_case
      end
    end

    test_case
  end
end
