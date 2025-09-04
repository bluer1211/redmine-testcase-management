class TestPlanImport < Import
  AUTO_MAPPABLE_FIELDS = {
    "test_plan_id" => "field_test_plan_id",
    "test_plan" => "field_test_plan",
    "test_plan_update" => "field_test_plan_update",
    "user" => "field_user",
    "issue_status" => "field_issue_status",
    "estimated_bug" => "field_estimated_bug",
    "begin_date" => "field_begin_date",
    "end_date" => "field_end_date",
    "test_case_ids" => "field_test_case_ids"
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
    # 修復: 確保 user 存在，如果沒有則使用 User.current
    current_user = user || User.current
    if current_user && !current_user.is_a?(AnonymousUser)
      Project.allowed_to(current_user, :add_test_plans)
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
    test_plan = TestPlan.new
    test_plan.user = user || User.current
    test_plan.project_id = mapping["project_id"].to_i

    # If test_plan_id is mapped, allow to override existing test plan
    test_plan_id = row_value(row, "test_plan_id")
    if test_plan_id
      found_test_plan = TestPlan.where(id: test_plan_id, project_id: test_plan.project_id).first
      if found_test_plan
        test_plan = found_test_plan
        test_plan.user = user || User.current
      end
    else
      name = row_value(row, "test_plan")
      found_test_plan = TestPlan.where(name: name, project_id: test_plan.project_id).first
      if found_test_plan
        test_plan = found_test_plan
        test_plan.user = user || User.current
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

    test_plan.send :safe_attributes=, attributes, user || User.current

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
