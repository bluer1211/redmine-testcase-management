class TestPlansController < ApplicationController

  def index
    @project = Project.find(params[:project_id])
    @plans = TestPlan.all
  end
end
