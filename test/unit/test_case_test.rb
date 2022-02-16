require File.expand_path('../../test_helper', __FILE__)

class TestCaseTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses

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
    test_case = TestCase.new(:id => 1,
                             :name => "dummy",
                             :scenario => "test scenario",
                             :expected => "expected situation",
                             :environment => "Debian GNU/Linux",
                             :project => Project.find(1),
                             :user => User.find(1),
                             :issue_status => IssueStatus.find(1))
    assert_save test_case
  end
end
