class TestPlansController < ApplicationController

  def index
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plans = TestPlan.all
  end

  def show
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plan = TestPlan.find(params.permit(:project_id, :id)[:id])
  end

  def edit
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plan = TestPlan.find(params.permit(:id)[:id])
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  def update
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

  def find_or_create_test_project(id_or_name)
    begin
      id = Integer(id_or_name)
      @project = Project.find(id)
      @test_project = TestProject.where(:project_id => @project.id).first
    rescue ArgumentError
      @project = project = Project.where(:name => id_or_name).first
      @test_project = TestProject.where(:project_id => @project.id).first
      unless @test_project.present?
        # automatically create it!
        @test_project = TestProject.create(:project_id => @project.id)
      end
    end
  end

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
