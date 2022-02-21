require File.expand_path('../../test_helper', __FILE__)

class TestCaseTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_cases

  def test_initialize
    test_case = TestCase.new

    assert_nil test_case.id
    assert_nil test_case.user_id
    assert_nil test_case.issue_status_id
    assert_nil test_case.project_id
    assert_nil test_case.name
    assert_nil test_case.scenario
    assert_nil test_case.expected
    assert_nil test_case.environment
  end

  def test_create
    test_case = TestCase.new(:id => 100,
                             :name => "dummy",
                             :scenario => "test scenario",
                             :expected => "expected situation",
                             :environment => "Debian GNU/Linux",
                             :project => Project.find(1),
                             :user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_save test_case
  end

  def test_fixture
    test_case = TestCase.find(1)
    assert_equal 1, test_case.id
    assert_equal "Test Case 1 (No test case execution)", test_case.name
    assert_equal "Scenario 1", test_case.scenario
    assert_equal "Expected 1", test_case.expected
    assert_equal "Debian GNU/Linux", test_case.environment
    assert_equal "2022-02-08 15:00:00 UTC", test_case.scheduled_date.to_s
    assert_equal 2, test_case.user_id
    assert_equal 1, test_case.project_id
    assert_equal 1, test_case.issue_status_id
  end

  def test_not_unique
    test_case = TestCase.new(:id => 1,
                             :name => "dummy",
                             :scenario => "test scenario",
                             :expected => "expected situation",
                             :environment => "Debian GNU/Linux",
                             :project => Project.find(1),
                             :user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_raises ActiveRecord::RecordNotUnique do
      test_case.save
    end
  end

  def test_missing_test_case
    assert_raises ActiveRecord::RecordNotFound do
      TestCase.find(999)
    end
  end

  def test_missing_project
    assert_raises ActiveRecord::RecordNotFound do
      TestCase.new(:project => Project.find(999))
    end
  end

  def test_missing_name
    object = TestCase.create(:scenario => "dummy",
                             :expected => "dummy",
                             :user => User.find(1),
                             :environment => "dummy",
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:name]
  end

  def test_missing_scenario
    object = TestCase.create(:name => "dummy",
                             :expected => "dummy",
                             :user => User.find(1),
                             :environment => "dummy",
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:scenario]
  end

  def test_missing_expected
    object = TestCase.create(:name => "dummy",
                             :scenario => "dummy",
                             :user => User.find(1),
                             :environment => "dummy",
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:expected]
  end

  def test_missing_user
    object = TestCase.create(:name => "dummy",
                             :scenario => "dummy",
                             :expected => "dummy",
                             :environment => "dummy",
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_environment
    object = TestCase.create(:name => "dummy",
                             :scenario => "dummy",
                             :expected => "dummy",
                             :user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:environment]
  end

  def test_missing_issue_status
    object = TestCase.create(:name => "dummy",
                             :scenario => "dummy",
                             :expected => "dummy",
                             :environment => "dummy",
                             :user => User.find(1))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:issue_status]
  end
end
