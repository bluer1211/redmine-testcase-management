class TestPlansController < ApplicationController

  def index
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plans = TestPlan.all
  end

  def show
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    begin
      @test_plan = TestPlan.find(params.permit(:project_id, :id)[:id])
    rescue
      flash.now[:error] = l(:error_test_plan_not_found)
      render 'forbidden', status: 404
    end
  end

  def edit
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plan = TestPlan.find(params.permit(:id)[:id])
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  def update
    @test_plan = TestPlan.find(params.permit(:id)[:id])
    update_params = {}
    update_params[:name] = test_plan_params[:name]
    update_params[:begin_date] = test_plan_params[:begin_date]
    update_params[:end_date] = test_plan_params[:end_date]
    update_params[:estimated_bug] = test_plan_params[:estimated_bug]
    user = User.find(test_plan_params[:user])
    update_params[:user_id] = user.id if user.present?
    issue_status = IssueStatus.find(test_plan_params[:issue_status])
    update_params[:issue_status_id] = issue_status.id if issue_status.present?
    if @test_plan.update(update_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_test_plan_path
    else
      flash.now[:error] = l(:error_update_failure)
      render :edit
    end
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
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_plan_path(:id => @test_plan.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    find_or_create_test_project(params.permit(:project_id)[:project_id])
    @test_plan = TestPlan.find(params.permit(:id)[:id])
    if @test_plan.delete
      flash[:notice] = l(:notice_successful_delete)
      redirect_to project_test_plans_path
    else
      flash.now[:error] = l(:error_delete_failure)
      render :show
    end
  end

  private

  def find_or_create_test_project(id_or_identifier)
    begin
      @project = Project.find(id_or_identifier)
      @test_project = TestProject.where(:project_id => @project.id).first
    rescue ArgumentError
      @project = project = Project.where(:identifier => id_or_identifier).first
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
