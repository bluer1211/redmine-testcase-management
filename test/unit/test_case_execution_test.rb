require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issues, :issue_statuses

  def test_initialize
    test_case_execution = TestCaseExecution.new

    assert_nil test_case_execution.id
    assert_nil test_case_execution.user_id
    assert_nil test_case_execution.issue_id
    assert_nil test_case_execution.execution_date
    assert_nil test_case_execution.comment
    assert_equal false, test_case_execution.result
  end

  def test_create
    test_plan = TestPlan.new
    test_case_execution = TestCaseExecution.new(:id => 1,
                                                :result => true,
                                                :execution_date => "2022-02-28",
                                                :user => User.find(1),
                                                :test_plan => test_plan,
                                                :issue => Issue.find(1))
    assert_save test_case_execution
  end
end
