class TestPlanImportsController < ApplicationController
  before_action :find_project
  before_action :authorize_import
  
  def new
    @import = TestPlanImport.new
    @import.project_id = @project.id
    @import.settings = {'project_id' => @project.identifier}
  end
  
  def create
    @import = TestPlanImport.new
    @import.user = User.current
    @import.file = params[:file]
    @import.project_id = @project.id
    @import.settings = {'project_id' => @project.identifier}
    @import.set_default_settings(:project_id => @project.identifier)
    
    if @import.save
      redirect_to import_settings_path(@import)
    else
      render :action => 'new'
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_import
    unless User.current.allowed_to?(:add_test_plans, @project)
      render_403
    end
  end
end
