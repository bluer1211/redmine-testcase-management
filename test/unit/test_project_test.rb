require File.expand_path('../../test_helper', __FILE__)

class TestProjectTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_projects, :test_plans

  def test_initialize
    test_project = TestProject.new
    assert_nil test_project.project_id
  end

  def test_create
    test_project = TestProject.new(:id => 100)
    assert_save test_project
  end

  def test_fixture
    test_project = TestProject.find(1)
    assert_equal 1, test_project.id
  end

  def test_not_unique
    test_project = TestProject.new(:id => 1)
    assert_raises ActiveRecord::RecordNotUnique do
      test_project.save
    end
  end

  # Test Relations

  def test_empty_association
    test_project = TestProject.new
    assert_nil test_project.project
  end

  def test_association
    test_project = TestProject.find(2)
    assert_equal 1, test_project.project.id
  end

  def test_no_test_plan
    test_project = TestProject.find(1)
    assert_equal 0, test_project.test_plans.size
  end

  def test_one_test_plan
    test_project = TestProject.find(2)
    assert_equal ["Test Plan (No test case)"], test_project.test_plans.pluck(:name)
  end

  def test_many_test_plan
    test_project = TestProject.find(3)
    assert_equal ["Test Plan (1 test case)",
                  "Test Plan (2 test cases)"], test_project.test_plans.pluck(:name)
  end

  def test_no_test_case
    test_project = TestProject.find(1)
    assert_equal [], test_project.test_cases.pluck(:name)
  end

  def test_many_test_case
    test_project = TestProject.find(3)
    assert_equal ["Test Case 1 (No test case execution)",
                  "Test Case 2 (1 test case execution)",
                  "Test Case 3 (2 test case execution)"],
                 test_project.test_cases.pluck(:name)
  end

  def test_no_test_case_execution
    test_project = TestProject.find(2)
    assert_equal [], test_project.test_case_executions.pluck(:comment)
  end

  def test_many_test_case_executions
    test_project = TestProject.find(3)
    assert_equal ["Comment 1", "Comment 2", "Comment 3"],
                 test_project.test_case_executions.pluck(:comment)
  end
end
