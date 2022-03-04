require File.expand_path('../../test_helper', __FILE__)

class TestPlanTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_projects, :test_plans, :test_cases

  def test_initialize
    test_plan = TestPlan.new

    assert_nil test_plan.id
    assert_nil test_plan.user_id
    assert_nil test_plan.issue_status_id
    assert_nil test_plan.name
    assert_nil test_plan.begin_date
    assert_nil test_plan.end_date
    assert_nil test_plan.estimated_bug
  end

  def test_create
    test_plan = TestPlan.new(:id => 100,
                             :name => "dummy",
                             :begin_date => "2022-02-16",
                             :end_date => "2022-02-28",
                             :estimated_bug => 10,
                             :user => users(:users_001),
                             :issue_status => issue_statuses(:issue_statuses_001))
    assert_save test_plan
    assert test_plan.destroy
  end

  def test_fixture
    test_plan = test_plans(:test_plans_001)
    assert_equal 1, test_plan.id
    assert_equal "Test Plan (No test case)", test_plan.name
    assert_equal 10, test_plan.estimated_bug
    assert_equal 2, test_plan.user_id
    assert_equal 1, test_plan.issue_status_id
    assert_equal "2022-01-31 15:00:00 UTC", test_plan.begin_date.to_s
    assert_equal "2022-02-27 15:00:00 UTC", test_plan.end_date.to_s
  end

  def test_not_unique
    test_plan = TestPlan.new(:id => test_plans(:test_plans_001).id,
                             :name => "dummy",
                             :begin_date => "2022-02-16",
                             :end_date => "2022-02-28",
                             :estimated_bug => 10,
                             :user => users(:users_001),
                             :issue_status => issue_statuses(:issue_statuses_001))
    assert_raises ActiveRecord::RecordNotUnique do
      test_plan.save
    end
  end

  def test_missing_test_project
    assert_raises ActiveRecord::RecordNotFound do
      TestPlan.create(:test_project => TestProject.find(999))
    end
  end

  def test_missing_name
    object = TestPlan.new(:user => users(:users_001),
                          :issue_status => issue_statuses(:issue_statuses_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:name]
  end

  def test_missing_user
    object = TestPlan.new(:name => "dummy",
                          :issue_status => issue_statuses(:issue_statuses_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_issue_status
    object = TestPlan.new(:name => "dummy",
                          :user => users(:users_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:issue_status]
  end

  # Test Relations

  def test_association
    test_plan = TestPlan.new
    assert_nil test_plan.user
    assert_nil test_plan.issue_status
    assert_nil test_plan.test_project
    assert_equal [], test_plan.test_cases.pluck(:id)
    assert_equal [], test_plan.test_case_executions.pluck(:id)
  end

  def test_no_test_case
    test_plan = test_plans(:test_plans_001)
    assert 0, test_plan.test_cases.size
  end

  def test_one_test_case
    test_plan = test_plans(:test_plans_002)
    assert 1, test_plan.test_cases.size
    assert "Test Case 1 (No test case execution)", test_plan.test_cases.pluck(:name)
  end

  def test_many_test_case
    test_plan = test_plans(:test_plans_003)
    assert 2, test_plan.test_cases.size
    assert ["Test Case 2 (1 test case execution)",
            "Test Case 3 (2 test case execution)"], test_plan.test_cases.pluck(:name)
  end

  def test_incomplete_test_case
    test_plan = test_plans(:test_plans_001)
    test_case = test_plan.test_cases.new(:name => "dummy")
    assert_equal true, test_case.invalid? # no test case name
    assert_equal false, test_plan.save
  end

  def test_save_test_case
    test_plan = test_plans(:test_plans_001)
    test_case = test_plan.test_cases.new(:name => "dummy",
                                         :scenario => "test scenario",
                                         :expected => "expected situation",
                                         :environment => "Debian GNU/Linux",
                                         :test_plan => test_plan,
                                         :test_project => test_projects(:test_projects_001),
                                         :user => users(:users_001),
                                         :issue_status => issue_statuses(:issue_statuses_001))
    assert_save test_plan
    assert_equal 1, test_plan.test_cases.size
    assert_equal test_plan, test_plan.test_cases.first.test_plan
    test_case.destroy
  end

  def test_destroy_dependent_test_case
    test_plan = test_plans(:test_plans_001)
    test_case = test_plan.test_cases.new(:name => "dummy",
                                         :scenario => "test scenario",
                                         :expected => "expected situation",
                                         :environment => "Debian GNU/Linux",
                                         :test_plan => test_plan,
                                         :test_project => test_projects(:test_projects_001),
                                         :user => users(:users_001),
                                         :issue_status => issue_statuses(:issue_statuses_001))
    assert_save test_plan
    assert_difference("TestPlan.count", -1) do
      assert_difference("TestCase.count", -1) do
        test_plan.destroy
      end
    end
  end
end
