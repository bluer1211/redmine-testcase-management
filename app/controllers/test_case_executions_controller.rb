class TestCaseExecutionsController < ApplicationController

  include ApplicationsHelper

  before_action :find_project_id
  before_action :find_test_plan_id_if_given, :only => [:new, :create, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case_id_if_given, :only => [:new, :create, :show, :edit, :index, :update, :destroy]
  before_action :find_test_case_execution, :only => [:show, :edit, :update, :destroy]
  before_action :authorize_with_issues_permission, :except => [:template]
  before_action :find_test_case_executions, :only => [:list_context_menu, :bulk_edit, :bulk_update, :bulk_delete]

  before_action do
    prepare_user_candidates
  end

  helper :attachments
  helper :queries
  include QueriesHelper
  helper :test_case_executions_queries
  include TestCaseExecutionsQueriesHelper
  helper :context_menus

  # GET /projects/:project_id/test_case_executions
  # GET /projects/:project_id/test_cases/:test_case_id/test_case_executions
  # GET /projects/:project_id/test_plans/:test_plan_id/test_case_executions
  # GET /projects/:project_id/test_plans/:test_plan_id/test_cases/:test_case_id:/test_case_executions
  def index
    retrieve_query(TestCaseExecutionQuery, false)

    @toplevel_test_case_execution = toplevel_test_case_execution?
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
    unless User.current.allowed_to?(:add_test_case_executions, @project, :global => true)
      raise ::Unauthorized
    end
    begin
      # 處理 result 參數，確保它是布林值
      result_value = test_case_execution_params[:result]
      if result_value.is_a?(String)
        result_value = result_value == 'true' || result_value == '1'
      end
      
      create_params = {
        result: result_value,
        user: User.find(test_case_execution_params[:user]),
        comment: test_case_execution_params[:comment],
        execution_date: test_case_execution_params[:execution_date],
        test_plan: @test_plan,
        test_case: @test_case,
        project: @project,
      }
      if test_case_execution_params[:issue_id].present?
        create_params[:issue_id] = test_case_execution_params[:issue_id]
      end
      @test_case_execution = TestCaseExecution.new(create_params)
      # 附件功能暫時停用，避免 acts_as_attachable 錯誤
      # if params[:attachments].present?
      #   @test_case_execution.save_attachments params.require(:attachments).permit!
      # end
      if @test_case_execution.valid?
        @test_case_execution.save
        # FIXME: unsaved_attachments will not be cleared
        # render_attachment_warning_if_needed @test_case_execution
        flash[:notice] = l(:notice_successful_create)
        
        # 智能重定向：根據來源決定重定向到哪裡
        if params[:continue]
          # 如果用戶選擇繼續，重定向到新增頁面
          redirect_to new_project_test_plan_test_case_test_case_execution_path(
            test_plan_id: @test_plan.id, 
            test_case_id: @test_case.id
          )
        else
          # 否則重定向到測試案例頁面
          redirect_to project_test_plan_test_case_path(
            test_plan_id: @test_plan.id, 
            id: @test_case.id
          )
        end
      else
        flash.now[:error] = l(:error_create_failure)
        render :new, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Test case execution creation failed: #{e.message}"
      flash.now[:error] = l(:error_create_failure)
      render :new, status: :unprocessable_entity
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
      # 附件功能暫時停用，避免 acts_as_attachable 錯誤
      # if params[:attachments].present?
      #   @test_case_execution.save_attachments params.require(:attachments).permit!
      # end
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

  # GET /projects/:project_id/test_case_executions/context_menu
  def list_context_menu
    if @test_case_executions.size == 1
      @test_case_execution = @test_case_executions.first
    end
    @test_case_execution_ids = @test_case_executions.map(&:id).sort

    edit_allowed = @test_case_executions.all? {|t| t.editable?(User.current)}
    @can = {:edit => edit_allowed, :delete => edit_allowed}
    @back = back_url

    @safe_attributes = @test_case_executions.map(&:safe_attribute_names).reduce(:&)
    @assignables = @project.users
    render :layout => false
  end

  def bulk_edit
    @assignables = @project.users
    @safe_attributes = @test_case_executions.map(&:safe_attribute_names).reduce(:&)
    @test_case_execution_params = params[:test_case_execution] || {}
    @back_url = params[:back_url]
  end

  def bulk_update
    attributes = parse_params_for_bulk_update(params[:test_case_execution])

    unsaved_test_case_executions = []
    saved_test_case_executions = []

    @test_case_executions.each do |orig_test_case_execution|
      orig_test_case_execution.reload
      test_case_execution = orig_test_case_execution
      test_case_execution.safe_attributes = attributes
      if test_case_execution.save
        saved_test_case_executions << test_case_execution
      else
        unsaved_test_case_executions << orig_test_case_execution
      end
    end

    if unsaved_test_case_executions.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_test_case_executions.empty?
      redirect_to params[:back_url]
    else
      @saved_test_case_executions = @test_case_executions
      @unsaved_test_case_executions = unsaved_test_case_executions
      @test_case_executions = TestPlan.visible.where(id: @unsaved_test_case_executions.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
    end
  end

  # DELETE /projects/:project_id/test_plans/bulk_delete
  def bulk_delete
    @test_case_execution_params = params[:test_case_execution] || {}

    delete_allowed = @test_case_executions.all? { |t| t.deletable?(User.current) }
    if delete_allowed
      @test_case_executions.destroy_all
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:error_delete_failure)
    end
    redirect_to params[:back_url]
  end

  # GET /projects/:project_id/test_case_executions/template
  def template
    # 完全移除權限檢查，讓模板下載對所有用戶開放
    
    case params[:type]
    when 'test_case_executions'
      generate_test_case_executions_template
    when 'test_cases'
      generate_test_cases_template
    when 'test_plans'
      generate_test_plans_template
    else
      generate_test_case_executions_template
    end
  end

  private

  def generate_test_case_executions_template
    @query = TestCaseExecutionQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭，但添加 test_case_execution_id 欄位
      headers = columns.map {|c| c.caption.to_s}
      headers.unshift(l(:field_test_case_execution_id))  # 在開頭添加測試案例執行 ID 欄位
      csv << headers
      # 添加範例資料行
      csv << [
        "1",  # test_case_execution_id
        "1",  # id
        "範例測試案例 1",
        "範例測試計劃 1",
        l(:label_succeed),
        User.current.name,
        "1",
        "執行備註",
        "測試步驟...",
        "預期結果...",
        "2024-01-01 10:00:00"
      ]
    end
    
    send_data csv_data,
              filename: "test_case_executions_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_test_cases_template
    @query = TestCaseQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭
      csv << columns.map {|c| c.caption.to_s}
      # 添加範例資料行
      csv << [
        "1",
        "範例測試案例 1",
        "Ubuntu",
        User.current.name,
        l(:label_succeed),
        "2024-01-01",
        "執行測試步驟...",
        "預期結果..."
      ]
    end
    
    send_data csv_data,
              filename: "test_cases_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def generate_test_plans_template
    @query = TestPlanQuery.new
    @query.project = @project
    columns = @query.available_columns
    
    csv_data = Redmine::Export::CSV.generate(encoding: 'UTF-8') do |csv|
      # 使用與 CSV 匯出相同的表頭
      csv << columns.map {|c| c.caption.to_s} + [l(:field_test_cases)]
      # 添加範例資料行
      csv << [
        "1",
        "範例測試計劃 1",
        l(:label_new),
        "1",
        User.current.name,
        "2024-01-01",
        "2024-01-31",
        "101,102,103"
      ]
    end
    
    send_data csv_data,
              filename: "test_plans_template.csv",
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment'
  end

  def toplevel_test_case_execution?
    params[:test_plan_id].nil? and
      params[:test_case_id].nil?
  end

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
      value.name
    when :result
      value ? l(:label_succeed) : l(:label_failure)
    else
      super
    end
  end

  def query_to_csv(items, query, options={})
    columns = query.columns

    Redmine::Export::CSV.generate(:encoding => params[:encoding]) do |csv|
      # csv header fields
      csv << columns.map {|c| c.caption.to_s}
      # csv lines
      items.each do |item|
        csv << columns.map {|c| csv_content(c, item)}
      end
    end
  end

  def csv_content(column, item)
    value = item.send(column.name) if item.respond_to?(column.name)
    case value
    when Date
      format_date(value)
    when Time
      format_time(value)
    when Array
      value.join(', ')
    else
      value.to_s
    end
  end
end
