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
    User.all.each do |user|
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

  # mainly copied from Rails's ApplicationController#authorize
  def authorize_with_issues_permission(controller = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?({controller: "issues", action: action}, @project || @projects, :global => global)
    if allowed
      true
    else
      if @project && @project.archived?
        @archived_project = @project
        render_403 :message => :notice_not_authorized_archived_project
      elsif @project && !@project.allows_to?(controller: controller, action: action)
        # Project module is disabled
        render_403
      else
        deny_access
      end
      false
    end
  end
end
