class TestPlansController < ApplicationController

  def index
    @project = Project.find(params.permit(:project_id)[:project_id])
    @test_plans = TestPlan.all
  end

  def show
    @test_plan = TestPlan.find(test_plan_params[:id])
  end

  def new
    @test_plan = TestPlan.new
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  def create
    prepare_issue_status_candidates
    prepare_user_candidates
    @test_plan = TestPlan.new(:name => test_plan_params[:name],
                              :begin_date => test_plan_params[:begin_date],
                              :end_date => test_plan_params[:end_date],
                              :user => User.find(test_plan_params[:user].to_i),
                              :estimated_bug => test_plan_params[:estimated_bug],
                              :issue_status => IssueStatus.find(test_plan_params[:issue_status].to_i))
    if @test_plan.valid?
      @test_plan.save
      redirect_to project_test_plans_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def test_plan_params
    params.require(:test_plan).permit(:project_id,
                                      :test_project_id,
                                      :name,
                                      :user,
                                      :begin_date,
                                      :end_date,
                                      :estimated_bug,
                                      :issue_status)
  end

  def prepare_issue_status_candidates
    @issue_status_candidates = {}
    IssueStatus.all.each do |issue_status|
      @issue_status_candidates[issue_status.name] =  issue_status.id
    end
  end

  def prepare_user_candidates
    @user_candidates = {}
    User.all.each do |user|
      @user_candidates[user.name] =  user.id
    end
  end
end
