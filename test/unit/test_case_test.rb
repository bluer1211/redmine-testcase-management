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
    test_case = TestCase.new(:id => 2,
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
    assert_equal "Dummy Test Case 1", test_case.name
    assert_equal "Dummy Scenario 1", test_case.scenario
    assert_equal "Dummy Expected 1", test_case.expected
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

  def test_missing_user
    assert_raises ActiveRecord::RecordNotFound do
      TestCase.new(:user => User.find(999))
    end
  end

  def test_missing_issue_status
    assert_raises ActiveRecord::RecordNotFound do
      TestCase.new(:issue_status => IssueStatus.find(999))
    end
  end
end
