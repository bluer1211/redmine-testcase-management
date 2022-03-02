class TestCasesController < ApplicationController

  def index
    find_test_project(params.permit(:project_id)[:project_id])
    @test_cases = TestCase.all
  end

  def new
    @test_case = TestCase.new
    prepare_issue_status_candidates
    prepare_user_candidates
  end

  def create
    prepare_issue_status_candidates
    prepare_user_candidates
    @test_case = TestCase.new(:name => test_case_params[:name],
                              :scheduled_date => test_case_params[:scheduled_date],
                              :user => User.find(test_case_params[:user]),
                              :environment => test_case_params[:environment],
                              :scenario => test_case_params[:scenario],
                              :expected => test_case_params[:expected],
                              :issue_status => IssueStatus.find(test_case_params[:issue_status]))
    if @test_case.valid?
      @test_case.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_test_case_path(:id => @test_case.id)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def test_case_params
    params.require(:test_case).permit(:project_id,
                                      :test_project_id,
                                      :name,
                                      :user,
                                      :scheduled_date,
                                      :environment,
                                      :scenario,
                                      :expected,
                                      :issue_status)
  end

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

  def prepare_issue_status_candidates
    @issue_status_candidates = {}
    IssueStatus.all.each do |issue_status|
      @issue_status_candidates[issue_status.name] = issue_status.id
    end
  end

  def prepare_user_candidates
    @user_candidates = {}
    User.all.each do |user|
      @user_candidates[user.name] = user.id
    end
  end
end
