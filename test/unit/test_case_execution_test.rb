require File.expand_path('../../test_helper', __FILE__)

class TestCaseExecutionTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issues, :issue_statuses
  fixtures :test_plans, :test_case_executions

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
                                                :user => User.find(1),
                                                :test_plan => test_plan,
                                                :issue => Issue.find(1))
    assert_save test_case_execution
  end

  def test_fixture
    test_case_execution = TestCaseExecution.find(1)
    assert_equal 1, test_case_execution.id
    assert_equal "Comment 1", test_case_execution.comment
    assert_equal "2022-02-09 15:00:00 UTC", test_case_execution.execution_date.to_s
    assert_equal 2, test_case_execution.user_id
    assert_equal 1, test_case_execution.issue_id
    assert_equal 2, test_case_execution.test_plan_id
  end

  def test_not_unique
    test_plan = TestPlan.find(1)
    test_case_execution = TestCaseExecution.new(:id => 1,
                                                :result => true,
                                                :comment => "dummy",
                                                :execution_date => "2022-02-28",
                                                :user => User.find(2),
                                                :test_plan => test_plan,
                                                :issue => Issue.find(1))
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
    object = TestCaseExecution.create(:comment => "dummy",
                                      :user => User.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:result]
  end

  def test_missing_user
    object = TestCaseExecution.create(:result => false,
                                      :comment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_comment
    object = TestCaseExecution.create(:result => false,
                                      :user => User.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:comment]
  end

  # Test Relation
  def test_empty_association
    test_case_execution = TestCaseExecution.new
    assert_nil test_case_execution.user
    assert_nil test_case_execution.project
    assert_nil test_case_execution.issue
    assert_nil test_case_execution.test_plan
    assert_nil test_case_execution.test_case
  end

  def test_association
    test_case_execution = TestCaseExecution.find(1)
    assert_equal 1, test_case_execution.issue.id
    assert_equal 2, test_case_execution.user.id
    assert_equal 2, test_case_execution.test_case.id
    # T.B.D.
    #assert_equal 2, test_case_execution.project.id
  end

  def test_no_issue
    test_case_execution = TestCaseExecution.find(2)
    assert_nil test_case_execution.issue
  end
end
