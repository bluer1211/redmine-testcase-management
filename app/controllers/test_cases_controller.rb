class TestCasesController < ApplicationController

  include ApplicationsHelper

  before_action do
    prepare_user_candidates
    prepare_issue_status_candidates
    prepare_test_plan_candidates
  end

  def index
    find_test_project(params.permit(:project_id)[:project_id])
    @test_cases = TestCase.all
  end

  def new
    @test_case = TestCase.new
    if params.permit(:test_plan_id)[:test_plan_id]
      @test_plan = TestPlan.find(params.permit(:test_plan_id)[:test_plan_id])
    else
      @test_plan = nil
    end
  end

  def create
    @test_case = TestCase.new(:name => test_case_params[:name],
                              :scheduled_date => test_case_params[:scheduled_date],
                              :user => User.find(test_case_params[:user]),
                              :test_plan => TestPlan.find(test_case_params[:test_plan_id]),
                              :environment => test_case_params[:environment],
                              :scenario => test_case_params[:scenario],
                              :expected => test_case_params[:expected],
                              :issue_status => IssueStatus.find(test_case_params[:issue_status]))
    if @test_case.valid?
      @test_case.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_plan_test_case_path(:id => @test_case.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case = TestCase.find(params.permit(:id)[:id])
  end

  def edit
    prepare_issue_status_candidates
    prepare_user_candidates
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case = TestCase.find(params.permit(:id)[:id])
    @test_plan = @test_case.test_plan
  end

  def update
    @test_case = TestCase.find(params.permit(:id)[:id])
    update_params = {
      name: test_case_params[:name],
      scheduled_date: test_case_params[:scheduled_date],
      scenario: test_case_params[:scenario],
      expected: test_case_params[:expected],
      environment: test_case_params[:environment]
    }
    user = User.find(test_case_params[:user])
    update_params[:user_id] = user.id if user.present?
    issue_status = IssueStatus.find(test_case_params[:issue_status])
    update_params[:issue_status_id] = issue_status.id if issue_status.present?
    if @test_case.update(update_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_test_plan_test_case_path
    else
      flash.now[:error] = l(:error_update_failure)
      render :edit
    end
  end

  def destroy
    @test_case = TestCase.find(params.permit(:id)[:id])
    if @test_case.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to project_test_plan_test_cases_path
    else
      flash.now[:error] = l(:error_delete_failure)
      render :show
    end
  end

  private

  def test_case_params
    params.require(:test_case).permit(:project_id,
                                      :test_project_id,
                                      :test_plan_id,
                                      :name,
                                      :user,
                                      :scheduled_date,
                                      :environment,
                                      :scenario,
                                      :expected,
                                      :issue_status)
  end

end
