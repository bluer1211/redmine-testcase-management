class TestCaseImportsController < ApplicationController
  before_action :find_project
  before_action :authorize_import
  
  layout :import_layout
  
  helper :issues
  helper :queries
  
  def new
    @import = TestCaseImport.new
    @import.project_id = @project.id
    @import.settings = {'project_id' => @project.identifier}
  end
  
  def create
    @import = TestCaseImport.new
    @import.user = User.current
    @import.file = params[:file]
    @import.project_id = @project.id
    @import.settings = {'project_id' => @project.identifier}
    @import.set_default_settings(:project_id => @project.identifier)
    
    if @import.save
      # 重定向到標準的匯入設置頁面
      redirect_to import_settings_path(@import)
    else
      render :action => 'new'
    end
  end
  
  private
  
  def find_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def authorize_import
    if @project
      unless User.current.allowed_to?(:add_test_cases, @project, :global => true)
        deny_access
      end
    else
      # 如果沒有專案，檢查全局權限
      unless User.current.allowed_to?(:add_test_cases, nil, :global => true)
        deny_access
      end
    end
  end
  
  def import_layout
    'base'
  end
end
