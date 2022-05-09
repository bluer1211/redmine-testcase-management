class TestCaseExecutionsController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan_id, :except => [:index, :show, :edit, :update]
  before_action :find_test_plan_id_if_given, :only => [:index, :show, :edit, :update]
  before_action :find_test_case_id, :only => [:show, :new, :create, :edit, :update, :destroy]
  before_action :find_test_case_id_if_given, :only => [:index]
  before_action :find_test_case_execution, :except => [:index, :new, :create]
  before_action :authorize_with_issues_permission, :except => [:index, :new, :create]

  before_action do
    prepare_user_candidates
  end

  helper :attachments
  helper :queries
  include QueriesHelper
  helper :test_case_executions_queries
  include TestCaseExecutionsQueriesHelper

  # GET /projects/:project_id/test_case_executions
  # GET /projects/:project_id/test_cases/:test_case_id/test_case_executions
  # GET /projects/:project_id/test_plans/:test_plan_id/test_case_executions
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions
  def index
    retrieve_query(TestCaseExecutionQuery, false)

    if @query.valid?
      @test_case_executions_export_limit = Setting.plugin_testcase_management["test_case_executions_export_limit"].to_i
      respond_to do |format|
        format.html do
          @test_case_execution_count = @query.test_case_execution_count
          @test_case_execution_pages = Paginator.new @test_case_execution_count, per_page_option, params['page']
          test_case_executions_params = {offset: @test_case_execution_pages.offset,
                                         limit: @test_case_execution_pages.per_page}
          if params[:test_plan_id].present?
            test_case_executions_params[:test_plan_id] = params[:test_plan_id]
          end
          if params[:test_case_id].present?
            test_case_executions_params[:test_case_id] = params[:test_case_id]
          end
          @test_case_executions = @query.test_case_executions(test_case_executions_params).visible
          if @test_plan and @test_case
            @title = html_title(l(:label_test_case_executions),
                                "##{@test_case.id} #{@test_case.name}",
                                l(:label_test_cases),
                                "##{@test_plan.id} #{@test_plan.name}",
                                l(:label_test_plans))
          elsif @test_plan
            @title = html_title(l(:label_test_case_executions),
                                "##{@test_plan.id} #{@test_plan.name}",
                                l(:label_test_plans))
          elsif @test_case
            @title = html_title(l(:label_test_case_executions),
                                "##{@test_case.id} #{@test_case.name}",
                                l(:label_test_cases))
          else
            @title = html_title(l(:label_test_case_executions))
          end
          @csv_url = project_test_case_executions_path(@project, test_case_executions_params.merge(format: "csv"))
        end
        format.csv do
          test_case_executions_params = {limit: @test_case_executions_export_limit}
          if params[:test_plan_id].present?
            test_case_executions_params[:test_plan_id] = params[:test_plan_id]
          end
          if params[:test_case_id].present?
            test_case_executions_params[:test_case_id] = params[:test_case_id]
          end
          @test_case_executions = @query.test_case_executions(test_case_executions_params).visible
          send_data(query_to_csv(@test_case_executions, @query, params[:csv]),
                    :type => 'text/csv; header=present', :filename => 'test_case_executions.csv')
        end
      end
    else
      flash.now[:error] = l(:error_index_failure)
      render 'forbidden', status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions/new
  def new
    @test_case_execution = TestCaseExecution.new
    @title = html_title(l(:label_test_case_execution_new),
                        "##{@test_case.id} #{@test_case.name}",
                        l(:label_test_cases),
                        "##{@test_plan.id} #{@test_plan.name}",
                        l(:label_test_plans))
    # FIXME:
    # @test_plan = @test_case_execution.test_plan
    # @test_case = @test_case_execution.test_case
    set_issue_template_uri
  end

  # POST /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions
  def create
    unless User.current.allowed_to?(:add_issues, @project, :global => true)
      raise ::Unauthorized
    end
    begin
      create_params = {
        result: test_case_execution_params[:result],
        user: User.find(test_case_execution_params[:user]),
        comment: test_case_execution_params[:comment],
        execution_date: test_case_execution_params[:execution_date],
        test_plan: @test_plan,
        test_case: @test_case,
        project: @project,
      }
      if test_case_execution_params[:issue_id]
        create_params[:issue_id] = test_case_execution_params[:issue_id]
      end
      @test_case_execution = TestCaseExecution.new(create_params)
      if params[:attachments].present?
        @test_case_execution.save_attachments params.require(:attachments).permit!
      end
      if @test_case_execution.valid?
        @test_case_execution.save
        # FIXME: unsaved_attachments will not be cleared
        # render_attachment_warning_if_needed @test_case_execution
        flash[:notice] = l(:notice_successful_create)
        redirect_to project_test_plan_path(id: @test_plan.id)
      else
        render :new, status: :unprocessable_entity
      end
    rescue
      render 'forbidden', status: :unprocessable_entity
    end
  end

  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions/:id
  def show
    @title = html_title("#{l(:label_test_case_executions)} ##{@test_case_execution.id}",
                        "##{@test_case.id} #{@test_case.name}",
                        l(:label_test_cases),
                        "##{@test_plan.id} #{@test_plan.name}",
                        l(:label_test_plans))
  end

  # GET /projects/:project_id/test_case_executions/:id/edit
  # GET /projects/:project_id/test_cases/:test_case_id:/test_case_executions/:id/edit
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions/:id/edit
  def edit
    @title = html_title("#{l(:label_test_case_execution_edit)} ##{@test_case_execution.id}",
                        "##{@test_case.id} #{@test_case.name}",
                        l(:label_test_cases),
                        "##{@test_plan.id} #{@test_plan.name}",
                        l(:label_test_plans))
    set_issue_template_uri
  end

  # PUT /projects/:project_id/test_case_executions/:id
  # PUT /projects/:project_id/test_cases/:test_case_id:/test_case_executions/:id
  # PUT /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions/:id
  def update
    begin
      raise ::Unauthorized unless @test_case_execution.editable?
      @test_case_execution.execution_date = test_case_execution_params[:execution_date]
      @test_case_execution.result = test_case_execution_params[:result]
      @test_case_execution.comment = test_case_execution_params[:comment]
      user = User.find(test_case_execution_params[:user])
      @test_case_execution.user = user if user.present?
      if test_case_execution_params[:issue_id].present?
        issue = Issue.find(test_case_execution_params[:issue_id])
        @test_case_execution.issue = issue if issue.present?
      else
        @test_case_execution.issue = nil
      end
      if params[:attachments].present?
        @test_case_execution.save_attachments params.require(:attachments).permit!
      end
      if @test_case_execution.save
        render_attachment_warning_if_needed @test_case_execution
        flash[:notice] = l(:notice_successful_update)
        if @test_plan_given
          redirect_to project_test_plan_test_case_path(test_plan_id: @test_plan.id,
                                                       id: @test_case.id)
        else
          redirect_to project_test_case_path(id: @test_case.id)
        end
      else
        flash.now[:error] = l(:error_update_failure)
        render :edit, status: :unprocessable_entity
      end
    rescue ::Unauthorized
    rescue
      flash.now[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  # DELETE /projects/:project_id/test_case_executions/:id
  # DELETE /projects/:project_id/test_cases/:test_case_id:/test_case_executions/:id
  # DELETE /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions/:id
  def destroy
    begin
      raise ::Unauthorized unless @test_case_execution.deletable?
      if @test_case_execution.destroy
        flash[:notice] = l(:notice_successful_delete)
        redirect_to project_test_plan_test_case_test_case_executions_path
      else
        flash.now[:error] = l(:error_delete_failure)
        render :show
      end
    rescue ::Unauthorized
    rescue
      flash.now[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
    end
  end

  private

  def find_test_case_execution
    find_params = {
      project_id: @project.id,
      id: params.permit(:id)[:id],
    }
    find_params[:test_plan_id] = @test_plan.id if @test_plan_given
    find_params[:test_case_id] = @test_case.id if @test_case_given
    @test_case_execution = TestCaseExecution.joins(:test_case).find_by(find_params)
    if @test_case_execution and @test_case_execution.visible?
      true
    else
      flash[:error] = l(:error_test_case_execution_not_found)
      render 'forbidden', status: 404
      false
    end
  end

  def permit_param(symbol)
    params.permit(symbol)[symbol]
  end

  def set_issue_template_uri
    @issue_template_uri = new_project_issue_path(@project) + "?"
    case Setting.text_formatting
    when "markdown"
      description =<<-EOS
# #{@test_plan.name} #{@test_case.name}

[#{@test_case.name}](#{project_test_plan_test_case_url(id: @test_case.id)})
EOS
      if @test_case_execution.id
        description +=<<EOS
[#{l(:label_test_case_executions)}](#{project_test_plan_test_case_test_case_execution_url(id: @test_case_execution.id)})

EOS
      end
      description +=<<-EOS
## #{l(:field_environment)}

#{@test_case.environment}

## #{l(:field_scenario)}

#{@test_case.scenario}

## #{l(:field_expected)}

#{@test_case.expected}

## #{l(:field_comment)}

#{@test_case_execution.comment}
EOS
    else
      description =<<-EOS
h1. #{@test_plan.name} #{@test_case.name}

"#{@test_case.name}":#{project_test_plan_test_case_url(id: @test_case.id)}
EOS
      if @test_case_execution.id
        description +=<<EOS
"#{l(:label_test_case_executions)}":#{project_test_plan_test_case_test_case_execution_url(id: @test_case_execution.id)}
EOS
      end
      description +=<<-EOS

h2. #{l(:field_environment)}

#{@test_case.environment}

h2. #{l(:field_scenario)}

#{@test_case.scenario}

h2. #{l(:field_expected)}

#{@test_case.expected}

h2. #{l(:field_comment)}

#{@test_case_execution.comment}
EOS
    end
    values = [["issue[assigned_to_id]", @test_case_execution.user ? @test_case_execution.user.id : User.current.id ],
              ["issue[subject]", "#{@test_plan.name} #{@test_case.name}"],
              ["issue[description]", description]]
    @issue_template_uri << URI.encode_www_form(values)
  end

  def test_case_execution_params
    params.require(:test_case_execution).permit(:project_id,
                                                :test_plan_id,
                                                :test_case_id,
                                                :user,
                                                :execution_date,
                                                :comment,
                                                :result,
                                                :issue_id)
  end

  def csv_value(column, test_case, value)
    case column.name
    when :test_plan, :test_case
      value.id
    when :result
      value ? l(:label_succeed) : l(:label_failure)
    else
      super
    end
  end
end
