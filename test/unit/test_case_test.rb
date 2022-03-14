require File.expand_path('../../test_helper', __FILE__)

class TestCaseTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :roles, :issue_statuses
  fixtures :test_plans, :test_cases, :test_case_executions

  def test_initialize
    test_case = TestCase.new

    assert_nil test_case.id
    assert_nil test_case.user_id
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
                             :project => projects(:projects_001),
                             :user => users(:users_001))
    assert_save test_case
    assert test_case.destroy
  end

  def test_fixture
    test_case = test_cases(:test_cases_001)
    assert_equal 1, test_case.id
    assert_equal "Test Case 1 (No test case execution)", test_case.name
    assert_equal "Scenario 1", test_case.scenario
    assert_equal "Expected 1", test_case.expected
    assert_equal "Debian GNU/Linux", test_case.environment
    assert_equal "2022-02-08 15:00:00 UTC", test_case.scheduled_date.to_s
    assert_equal users(:users_002), test_case.user
    assert_equal projects(:projects_003), test_case.project
  end

  def test_not_unique
    test_case = TestCase.new(:id => test_cases(:test_cases_001).id,
                             :name => "dummy",
                             :scenario => "test scenario",
                             :expected => "expected situation",
                             :environment => "Debian GNU/Linux",
                             :project => projects(:projects_001),
                             :user => users(:users_001))
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
    object = TestCase.new(:scenario => "dummy",
                          :expected => "dummy",
                          :user => users(:users_001),
                          :environment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:name]
  end

  def test_missing_scenario
    object = TestCase.new(:name => "dummy",
                          :expected => "dummy",
                          :user => users(:users_001),
                          :environment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:scenario]
  end

  def test_missing_expected
    object = TestCase.new(:name => "dummy",
                          :scenario => "dummy",
                          :user => users(:users_001),
                          :environment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:expected]
  end

  def test_missing_user
    object = TestCase.new(:name => "dummy",
                          :scenario => "dummy",
                          :expected => "dummy",
                          :environment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_environment
    object = TestCase.new(:name => "dummy",
                          :scenario => "dummy",
                          :expected => "dummy",
                          :user => users(:users_001))
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:environment]
  end

  # Test Relations

  def test_association
    test_case = TestCase.new
    assert_nil test_case.user
    assert_nil test_case.project
    assert_nil test_case.test_plan
  end

  def test_no_test_case_execution
    test_case = test_cases(:test_cases_001)
    assert 0, test_case.test_case_executions.size
  end

  def test_one_test_case_execution
    test_case = test_cases(:test_cases_002)
    assert 1, test_case.test_case_executions.size
    assert "Comment 1", test_case.test_case_executions.select(:comment)
  end

  def test_many_test_case_executions
    test_case = test_cases(:test_cases_003)
    assert 2, test_case.test_case_executions.size
    assert ["Comment 2",
            "Comment 3"], test_case.test_case_executions.select(:comment)
  end

  def test_incomplete_test_case_execution
    test_case = test_cases(:test_cases_001)
    test_case_execution = test_case.test_case_executions.new(:result => true,
                                                             :user => users(:users_001))
    assert_equal true, test_case_execution.invalid?
    assert_equal true, test_case.invalid?
    assert_equal false, test_case.save
    assert_equal 0, test_cases(:test_cases_001).reload.test_case_executions.size
  end

  def test_save_test_case
    test_case = test_cases(:test_cases_001)
    test_case_execution = test_case.test_case_executions.new(:result => true,
                                                             :comment => "dummy",
                                                             :user => users(:users_001))
    assert_equal true, test_case_execution.valid?
    assert_equal true, test_case.valid?
    assert_save test_case
    assert_equal 1, test_cases(:test_cases_001).test_case_executions.size
  end


  def test_test_case_should_editable_by_author
    Role.all.each do |role|
      role.remove_permission! :edit_issues
      role.add_permission! :edit_own_issues
    end

    test_case = test_cases(:test_cases_001)
    user = users(:users_002)

    assert_equal user, test_case.user
    assert_equal [true, true, false],
                 [
                   test_case.attributes_editable?(user), #author
                   test_case.attributes_editable?(users(:users_001)), #admin
                   test_case.attributes_editable?(users(:users_003)), #other
                 ]
  end
end
