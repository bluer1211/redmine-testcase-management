module ApplicationsHelper
  def find_test_project(id_or_name)
    begin
      id = Integer(id_or_name)
      @project = Project.find(id)
      @test_project = TestProject.where(:project_id => @project.id).first
    rescue ArgumentError
      @project = project = Project.where(:name => id_or_name).first
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

  def yyyymmdd_date(date)
    if date
      date.strftime("%Y/%m/%d")
    else
      "-"
    end
  end
end
