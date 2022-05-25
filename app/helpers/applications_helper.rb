module ApplicationsHelper
  def find_project(id_or_identifier)
    begin
      @project = Project.find(id_or_identifier)
    rescue ArgumentError
      @project = project = Project.find(:identifier => id_or_identifier).first
    end
  end

  def prepare_issue_status_candidates
    @issue_status_candidates = {}
    IssueStatus.all.each do |issue_status|
      @issue_status_candidates[issue_status.name] = issue_status.id
    end
  end

  def prepare_test_plan_candidates
    @test_plan_candidates = {}
    TestPlan.all.each do |test_plan|
      @test_plan_candidates[test_plan.name] = test_plan.id
    end
  end

  def prepare_user_candidates
    @user_candidates = {}
    if @project
      users = @project.users
    else
      users = User.all
    end
    users.each do |user|
      @user_candidates[user.name] = user.id
    end
  end

  def yyyymmdd_date(date, separator="/")
    if date
      date.strftime("%Y#{separator}%m#{separator}%d")
    else
      "-"
    end
  end

  def find_project_id
    @project = find_project(params.permit(:project_id)[:project_id])
    raise ActiveRecord::RecordNotFound unless @project
    true
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_project_not_found)
    render 'forbidden', status: 404
    false
  end

  def find_test_plan_id
    @test_plan_given = true
    @test_plan = TestPlan.find(params.permit(:test_plan_id)[:test_plan_id])
    raise ActiveRecord::RecordNotFound unless @test_plan.visible?
    true
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_plan_not_found)
    render 'forbidden', status: 404
    false
  end

  def find_test_plan_id_if_given
    if params[:test_plan_id].present?
      @test_plan_given = true
      find_test_plan_id
    else
      @test_plan_given = false
      @test_plan = nil
      true
    end
  end

  def find_test_plan
    @test_plan = TestPlan.find(params.permit(:id)[:id])
    raise ActiveRecord::RecordNotFound unless @test_plan.visible?
    true
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_plan_not_found)
    render 'forbidden', status: 404
    false
  end

  def find_test_case_id
    @test_case_given = true
    @test_case = TestCase.find(params.permit(:test_case_id)[:test_case_id])
    raise ActiveRecord::RecordNotFound unless @test_case.visible?
    true
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_case_not_found)
    render 'forbidden', status: 404
    false
  end

  def find_test_case_id_if_given
    if params[:test_case_id].present?
      @test_case_given = true
      find_test_case_id
    else
      @test_case_given = false
      @test_case = nil
      true
    end
  end

  def find_test_case
    @test_case = TestCase.find(params.permit(:id)[:id])
    raise ActiveRecord::RecordNotFound unless @test_case.visible?
    true
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_case_not_found)
    render 'forbidden', status: 404
    false
  end

  def find_test_cases
    # Used via context menu
    @test_cases = TestCase.where(id: params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @test_cases.empty?
    raise Unauthorized unless @test_cases.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_case_executions
    # Used via context menu
    @test_case_executions = TestCaseExecution.where(id: params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @test_case_executions.empty?
    raise Unauthorized unless @test_case_executions.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_test_plans
    # Used via context menu
    @test_plans = if params[:id] || params[:ids]
                    TestPlan.where(id: params[:id] || params[:ids])
                  else
                    find_project_id
                    TestPlan.where(project_id: @project.id)
                  end
    raise ActiveRecord::RecordNotFound if @test_plans.empty?
    raise Unauthorized unless @test_plans.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # mainly copied from Rails's ApplicationController#authorize
  def authorize_with_issues_permission(controller = params[:controller], action = params[:action], global = false)
    issue_allowed = User.current.allowed_to?({controller: "issues", action: related_issues_action(action)}, @project || @projects, :global => global)
    testcase_allowed = User.current.allowed_to?({controller: controller, action: action}, @project || @projects, :global => global)
    activated = !@project || @project.allows_to?(controller: controller, action: action)
    if issue_allowed and testcase_allowed and activated
      true
    else
      if @project && @project.archived?
        @archived_project = @project
        render_403 :message => :notice_not_authorized_archived_project
      elsif !activated
        # Project module is disabled
        render_403
      else
        deny_access
      end
      false
    end
  end

  def related_issues_action(action)
    case action.to_sym
    when :auto_complete, :statistics, :show_context_menu, :list_context_menu
      :index
    when :assign_test_case, :unassign_test_case, :bulk_edit
      :edit
    when :bulk_update
      :update
    when :bulk_delete
      :destroy
    else
      action
    end
  end

  def column_truncated_text(text, limit=10)
    contents = nil
    text.split("\n", 10).each do |line|
      unless contents
        contents = content_tag("p", truncate(line))
      else
        contents += content_tag("p", truncate(line))
      end
    end
    contents
  end
end
