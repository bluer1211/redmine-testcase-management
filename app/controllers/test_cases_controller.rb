class TestCasesController < ApplicationController

  def index
    find_test_project(params.permit(:project_id)[:project_id])
    @test_cases = TestCase.all
  end

  private

  def find_test_project(id_or_name)
    begin
      id = Integer(id_or_name)
      @project = Project.find(id)
      @test_project = TestProject.where(:project_id => @project.id).first
    rescue ArgumentError
      @project = project = Project.where(:name => id_or_name).first
      @test_project = TestProject.where(:project_id => @project.id).first
    end
  end
end
