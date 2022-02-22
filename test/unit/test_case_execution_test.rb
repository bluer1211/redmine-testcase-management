require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issues, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases, :test_case_executions

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
    test_case_execution = TestCaseExecution.new(:id => 100,
                                                :result => true,
                                                :execution_date => "2022-02-28",
                                                :comment => "dummy",
                                                :user => users(:users_001),
                                                :test_plan => test_plan,
                                                :issue => issues(:issues_001))
    assert_save test_case_execution
    assert test_case_execution.destroy
  end

  def test_fixture
    test_case_execution = test_case_executions(:test_case_executions_001)
    assert_equal 1, test_case_execution.id
    assert_equal "Comment 1", test_case_execution.comment
    assert_equal "2022-02-09 15:00:00 UTC", test_case_execution.execution_date.to_s
    assert_equal users(:users_002), test_case_execution.user
    assert_equal issues(:issues_001), test_case_execution.issue
    assert_equal test_plans(:test_plans_002), test_case_execution.test_plan
  end

  def test_not_unique
    test_plan = test_plans(:test_plans_001)
    test_case_execution = TestCaseExecution.new(:id => test_case_executions(:test_case_executions_001).id,
                                                :result => true,
                                                :comment => "dummy",
                                                :execution_date => "2022-02-28",
                                                :user => users(:users_002),
                                                :test_plan => test_plan,
                                                :issue => issues(:issues_001))
    assert_raises ActiveRecord::RecordNotUnique do
      test_case_execution.save
    end
  end

  def test_missing_test_case_execution
    assert_raises ActiveRecord::RecordNotFound do
      TestCaseExecution.find(999)
    end
  end

  def test_missing_test_plan
    assert_raises ActiveRecord::RecordNotFound do
      TestCaseExecution.new(:test_plan => TestPlan.find(999))
    end
  end

  def test_missing_result
    object = TestCaseExecution.new(:comment => "dummy",
                                   :user => users(:users_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:result]
  end

  def test_missing_user
    object = TestCaseExecution.new(:result => false,
                                   :comment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_comment
    object = TestCaseExecution.new(:result => false,
                                   :user => users(:users_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:comment]
  end

  # Test Relation
  def test_empty_association
    test_case_execution = TestCaseExecution.new
    assert_nil test_case_execution.user
    assert_nil test_case_execution.test_project
    assert_nil test_case_execution.issue
    assert_nil test_case_execution.test_plan
    assert_nil test_case_execution.test_case
  end

  def test_association
    test_case_execution = test_case_executions(:test_case_executions_001)
    assert_equal issues(:issues_001), test_case_execution.issue
    assert_equal users(:users_002), test_case_execution.user
    assert_equal test_cases(:test_cases_002), test_case_execution.test_case
    # T.B.D.
    #assert_equal 2, test_case_execution.test_project.id
  end

  def test_no_issue
    test_case_execution = test_case_executions(:test_case_executions_002)
    assert_nil test_case_execution.issue
  end
end
