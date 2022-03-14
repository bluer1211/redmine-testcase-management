class TestCaseExecutionsController < ApplicationController

  include ApplicationsHelper

  before_action :find_test_project_id, :only => [:new, :show, :edit, :index, :update, :destroy]
  before_action :find_test_plan_id, :only => [:new, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case_id, :only => [:show, :edit, :index, :update, :destroy]

  before_action do
    prepare_user_candidates
  end

  helper :attachments

  def index
    @test_case_executions = TestCaseExecution.joins(:test_case).where(test_project_id: @test_project.id,
                                                                      test_plan_id: @test_plan.id,
                                                                      test_case_id: @test_case.id)
  end

  def new
    find_test_project(params.permit(:project_id)[:project_id])
    @test_case_execution = TestCaseExecution.new
    # FIXME:
    # @test_plan = @test_case_execution.test_plan
    # @test_case = @test_case_execution.test_case
    @test_plan = TestPlan.find(permit_param(:test_plan_id))
    @test_case = TestCase.find(permit_param(:test_case_id))
  end

  def create
    begin
      find_test_project(params.permit(:project_id)[:project_id])
      @test_plan = TestPlan.find(permit_param(:test_plan_id))
      @test_case = TestCase.find(permit_param(:test_case_id))
      create_params = {
        result: test_case_execution_params[:result],
        user: User.find(test_case_execution_params[:user]),
        comment: test_case_execution_params[:comment],
        execution_date: test_case_execution_params[:execution_date],
        test_plan: @test_plan,
        test_case: @test_case
      }
      if test_case_execution_params[:issue_id]
        create_params[:issue_id] = test_case_execution_params[:issue_id]
      end
      @test_case_execution = TestCaseExecution.new(create_params)
      @test_case_execution.save_attachments params.require(:attachments).permit!
      if @test_case_execution.valid?
        render_attachment_warning_if_needed @test_case_execution
        @test_case_execution.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to project_test_plan_test_case_test_case_execution_path(:id => @test_case_execution.id)
      else
        render :new, status: :unprocessable_entity
      end
    rescue
      render 'forbidden', status: :unprocessable_entity
    end
  end

  def show
    @test_case_execution = TestCaseExecution.joins(:test_case).where(test_project_id: @test_project.id,
                                                                     test_plan_id: @test_plan.id,
                                                                     test_case_id: @test_case.id,
                                                                     id: params.permit(:id)[:id]).first
    if @test_case_execution
      render :show
    else
      flash[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  def edit
    @test_case_execution = TestCaseExecution.joins(:test_case).where(test_project_id: @test_project.id,
                                                                     test_plan_id: @test_plan.id,
                                                                     test_case_id: @test_case.id,
                                                                     id: params.permit(:id)[:id]).first
    if @test_case_execution
      render :edit
    else
      flash[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  def update
    begin
      @test_case_execution = TestCaseExecution.joins(:test_case).where(test_project_id: @test_project.id,
                                                                       test_plan_id: @test_plan.id,
                                                                       test_case_id: @test_case.id,
                                                                       id: params.permit(:id)[:id]).first

      unless @test_case_execution
        raise ActiveRecord::RecordNotFound
      end
      @test_case_execution.execution_date = test_case_execution_params[:execution_date]
      @test_case_execution.result = test_case_execution_params[:result]
      @test_case_execution.comment = test_case_execution_params[:comment]
      user = User.find(test_case_execution_params[:user])
      @test_case_execution.user = user if user.present?
      if test_case_execution_params[:issue_id].present?
        issue = Issue.find(test_case_execution_params[:issue_id])
        @test_case_execution.issue = issue if issue.present?
      end
      @test_case_execution.save_attachments params.require(:attachments).permit!
      if @test_case_execution.save
        render_attachment_warning_if_needed @test_case_execution
        flash[:notice] = l(:notice_successful_update)
        redirect_to project_test_plan_test_case_test_case_execution_path
      else
        flash.now[:error] = l(:error_update_failure)
        render :edit, status: :unprocessable_entity
      end
    rescue
      flash.now[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  def destroy
    begin
      @test_case_execution = TestCaseExecution.joins(:test_case).where(test_project_id: @test_project.id,
                                                                       test_plan_id: @test_plan.id,
                                                                       test_case_id: @test_case.id,
                                                                       id: params.permit(:id)[:id]).first

      unless @test_case_execution
        raise ActiveRecord::RecordNotFound
      end
      if @test_case_execution.destroy
        flash[:notice] = l(:notice_successful_delete)
        redirect_to project_test_plan_test_case_test_case_executions_path
      else
        flash.now[:error] = l(:error_delete_failure)
        render :show
      end
    rescue
      flash.now[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  private

  def permit_param(symbol)
    params.permit(symbol)[symbol]
  end

  def test_case_execution_params
    params.require(:test_case_execution).permit(:project_id,
                                                :test_project_id,
                                                :test_plan_id,
                                                :test_case_id,
                                                :user,
                                                :execution_date,
                                                :comment,
                                                :result,
                                                :issue_id)
  end
end
