require File.expand_path('../../test_helper', __FILE__)

class TestPlanTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_plans

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
    test_plan = TestPlan.create(:id => 100,
                                :name => "dummy",
                                :begin_date => "2022-02-16",
                                :end_date => "2022-02-28",
                                :estimated_bug => 10,
                                :user => User.find(1),
                                :issue_status => IssueStatus.find(1))
    assert_save test_plan
  end

  def test_fixture
    test_plan = TestPlan.find(1)
    assert_equal 1, test_plan.id
    assert_equal "Test Plan (No test case)", test_plan.name
    assert_equal 10, test_plan.estimated_bug
    assert_equal 2, test_plan.user_id
    assert_equal 1, test_plan.issue_status_id
    assert_equal "2022-01-31 15:00:00 UTC", test_plan.begin_date.to_s
    assert_equal "2022-02-27 15:00:00 UTC", test_plan.end_date.to_s
  end

  def test_not_unique
    test_plan = TestPlan.new(:id => 1,
                             :name => "dummy",
                             :begin_date => "2022-02-16",
                             :end_date => "2022-02-28",
                             :estimated_bug => 10,
                             :user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_raises ActiveRecord::RecordNotUnique do
      test_plan.save
    end
  end

  def test_missing_project
    assert_raises ActiveRecord::RecordNotFound do
      TestPlan.create(:project => Project.find(999))
    end
  end

  def test_missing_name
    object = TestPlan.create(:user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:name]
  end

  def test_missing_user
    object = TestPlan.create(:name => "dummy",
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_issue_status
    object = TestPlan.create(:name => "dummy",
                             :user => User.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:issue_status]
  end
end
