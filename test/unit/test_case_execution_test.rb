require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issues, :issue_statuses
  fixtures :test_case_executions

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
    test_case_execution = TestCaseExecution.new(:id => 2,
                                                :result => true,
                                                :execution_date => "2022-02-28",
                                                :user => User.find(1),
                                                :test_plan => test_plan,
                                                :issue => Issue.find(1))
    assert_save test_case_execution
  end

  def test_fixture
    test_case_execution = TestCaseExecution.find(1)
    assert_equal 1, test_case_execution.id
    assert_equal "Dummy Comment 1", test_case_execution.comment
    assert_equal "2022-02-09 15:00:00 UTC", test_case_execution.execution_date.to_s
    assert_equal 2, test_case_execution.user_id
    assert_equal 1, test_case_execution.issue_id
    assert_equal 1, test_case_execution.test_plan_id
  end

  def test_not_unique
    test_plan = TestPlan.new
    test_case_execution = TestCaseExecution.new(:id => 1,
                                                :result => true,
                                                :execution_date => "2022-02-28",
                                                :user => User.find(1),
                                                :test_plan => test_plan,
                                                :issue => Issue.find(1))
    assert_raises ActiveRecord::RecordNotUnique do
      test_case_execution.save
    end
  end
end
