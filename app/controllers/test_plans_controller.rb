class TestPlansController < ApplicationController

  include ApplicationsHelper

  before_action do
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  def index
    begin
      find_project(params.permit(:project_id)[:project_id])
      @test_plans = TestPlan.all
    rescue
      flash.now[:error] = l(:error_project_not_found)
      render 'forbidden', status: 404
    end
  end

  def show
    begin
      find_project(params.permit(:project_id)[:project_id])
      begin
        @test_plan = TestPlan.find(params.permit(:project_id, :id)[:id])
      rescue
        flash.now[:error] = l(:error_test_plan_not_found)
        render 'forbidden', status: 404
      end
    rescue
      flash.now[:error] = l(:error_project_not_found)
      render 'forbidden', status: 404
    end
  end

  def edit
    begin
      find_project(params.permit(:project_id)[:project_id])
      begin
        @test_plan = TestPlan.find(params.permit(:id)[:id])
      rescue
        flash.now[:error] = l(:error_test_plan_not_found)
        render 'forbidden', status: 404
      end
    rescue
      flash.now[:error] = l(:error_project_not_found)
      render 'forbidden', status: 404
    end
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
  end

  def create
    @test_plan = TestPlan.new(:name => test_plan_params[:name],
                              :begin_date => test_plan_params[:begin_date],
                              :end_date => test_plan_params[:end_date],
                              :user => User.find(test_plan_params[:user].to_i),
                              :estimated_bug => test_plan_params[:estimated_bug],
                              :issue_status => IssueStatus.find(test_plan_params[:issue_status].to_i),
                              :project => @project)
    if @test_plan.valid?
      @test_plan.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_plan_path(:id => @test_plan.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    begin
      find_project(params.permit(:project_id)[:project_id])
      begin
        @test_plan = TestPlan.find(params.permit(:id)[:id])
        if @test_plan.destroy
          flash[:notice] = l(:notice_successful_delete)
          redirect_to project_test_plans_path
        else
          flash.now[:error] = l(:error_delete_failure)
          render :show
        end
      rescue
        flash.now[:error] = l(:error_test_plan_not_found)
        render 'forbidden', status: 404
      end
    rescue
      flash.now[:error] = l(:error_project_not_found)
      render 'forbidden', status: 404
    end
  end

  private

  def test_plan_params
    params.require(:test_plan).permit(:project_id,
                                      :name,
                                      :user,
                                      :begin_date,
                                      :end_date,
                                      :estimated_bug,
                                      :issue_status)
  end
end
