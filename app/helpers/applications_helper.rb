module ApplicationsHelper
  def find_test_project(id_or_identifier)
    begin
      @project = Project.find(id_or_identifier)
      @test_project = TestProject.where(:project_id => @project.id).first
    rescue ArgumentError
      @project = project = Project.where(:identifier => id_or_identifier).first
      @test_project = TestProject.where(:project_id => @project.id).first
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

  def find_test_project_id
    @project = Project.where(:identifier => params[:project_id]).first
    raise ActiveRecord::RecordNotFound unless @project
    @test_project = TestProject.where(:project_id => @project.id).first
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_project_not_found)
    render 'forbidden', status: 404
  end

  def find_test_plan_id
    @test_plan = TestPlan.find(params[:test_plan_id])
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_plan_not_found)
    render 'forbidden', status: 404
  end

  def find_test_case_id
    @test_case = TestCase.find(params[:test_case_id])
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_case_not_found)
    render 'forbidden', status: 404
  end

  def find_test_case
    @test_case = TestCase.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = l(:error_test_case_not_found)
    render 'forbidden', status: 404
  end
end
