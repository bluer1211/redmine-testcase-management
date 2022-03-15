require File.expand_path("../../test_helper", __FILE__)

class TestPlanTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases

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

  def test_missing_project
    assert_raises ActiveRecord::RecordNotFound do
      TestPlan.create(:project => Project.find(999))
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
    assert_nil test_plan.project
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
                                         :project => projects(:projects_001),
                                         :user => users(:users_001))
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
                                         :project => projects(:projects_001),
                                         :user => users(:users_001))
    assert_save test_plan
    assert_difference("TestPlan.count", -1) do
      assert_difference("TestCase.count", -1) do
        test_plan.destroy
      end
    end
  end

  # permissions

  def assert_visibility_match(user, test_plans)
    assert_equal TestPlan.all.select {|test_plan| test_plan.visible?(user)}.collect(&:id).sort,
                 test_plans.collect(&:id).sort
  end

  def test_visible_scope_for_anonymous
    # Anonymous user should see test_plans of public projects only
    test_plans = TestPlan.visible(User.anonymous).to_a
    assert_equal [true, nil],
                 [test_plans.any?,
                  test_plans.detect {|test_plan| !test_plan.project.is_public?}]
    assert_visibility_match User.anonymous, test_plans
  end

  def test_visible_scope_for_anonymous_without_view_issues_permissions
    # Anonymous user should not see test_plans without permission
    Role.anonymous.remove_permission!(:view_issues)
    test_plans = TestPlan.visible(User.anonymous).to_a
    assert test_plans.empty?
    assert_visibility_match User.anonymous, test_plans
  end

  def test_visible_scope_for_anonymous_without_view_issues_permissions_and_membership
    Role.anonymous.remove_permission!(:view_issues)
    Member.create!(:project_id => 3, :principal => Group.anonymous, :role_ids => [2])

    test_plans = TestPlan.visible(User.anonymous).all
    assert_equal [true, [3]],
                 [test_plans.any?,
                  test_plans.map(&:project_id).uniq.sort]
    assert_visibility_match User.anonymous, test_plans
  end

  def test_visible_scope_for_non_member
    user = User.find(9)
    assert user.projects.empty?
    # Non member user should see test_plans of public projects only
    test_plans = TestPlan.visible(user).to_a
    assert_equal [true, nil],
                 [test_plans.any?,
                  test_plans.detect {|test_plan| !test_plan.project.is_public?}]
    assert_visibility_match user, test_plans
  end

  def test_visible_scope_for_non_member_with_own_test_plan_visibility
    Role.non_member.update! :issues_visibility => "own"
    user = User.find(9)
    TestPlan.create!(project_id: 3, name: "test plan by non member",
                     estimated_bug: 10, issue_status_id: 1,
                     user_id: user.id, begin_date: DateTime.new, end_date: DateTime.new)

    test_plans = TestPlan.visible(user).to_a
    assert_equal [true, nil],
                 [test_plans.any?,
                  test_plans.detect {|test_plan| test_plan.user != user}]
    assert_visibility_match user, test_plans
  end

  def test_visible_scope_for_non_member_without_view_test_plan_permissions
    # Non member user should not see test_plans without permission
    Role.non_member.remove_permission!(:view_issues)
    user = User.find(9)
    assert user.projects.empty?
    test_plans = TestPlan.visible(user).to_a
    assert test_plans.empty?
    assert_visibility_match user, test_plans
  end

  def test_visible_scope_for_non_member_without_view_test_plans_permissions_and_membership
    Role.non_member.remove_permission!(:view_issues)
    Member.create!(:project_id => 3, :principal => Group.non_member, :role_ids => [2])
    user = User.find(9)

    test_plans = TestPlan.visible(user).all
    assert test_plans.any?
    assert_equal [3], test_plans.map(&:project_id).uniq.sort
    assert_visibility_match user, test_plans
  end

  def test_visible_scope_for_member
    user = User.find(9)
    # User should see test_plans of projects for which user has view_issues permissions only
    Role.non_member.remove_permission!(:view_issues)
    Member.create!(:principal => user, :project_id => 3, :role_ids => [2])
    test_plans = TestPlan.visible(user).to_a
    assert_equal [true, nil],
                 [test_plans.any?,
                  test_plans.detect {|test_plan| test_plan.project_id != 3}]
    assert_visibility_match user, test_plans
  end

  def test_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
    Role.non_member.add_permission!(:view_issues)
    Role.find(1).remove_permission!(:view_issues)
    user = User.find(2)

    assert_equal [0, false],
                 [TestPlan.where(:project_id => 1).visible(user).count,
                  TestPlan.where(:project_id => 1).first.visible?(user)]
  end

  def test_visible_scope_with_custom_non_member_role_having_restricted_permission
    role = Role.generate!(:permissions => [:view_project])
    assert Role.non_member.has_permission?(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 1, :roles => [role])

    test_plans = TestPlan.visible(user).to_a
    assert_equal [true, nil],
                 [test_plans.any?,
                  test_plans.detect {|test_plan| test_plan.project_id == 1}]
  end

  def test_visible_scope_with_custom_non_member_role_having_extended_permission
    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 3, :roles => [role])

    test_plans = TestPlan.visible(user).to_a
    assert test_plans.any?
    assert_not_nil test_plans.detect {|test_plan| test_plan.project_id == 3}
  end

  def test_test_plan_should_editable_by_author
    Role.all.each do |role|
      role.remove_permission! :edit_issues
      role.add_permission! :edit_own_issues
    end

    test_plan = test_plans(:test_plans_002)
    user = users(:users_002)

    assert_equal user, test_plan.user
    assert_equal [true, true, false],
                 [
                   test_plan.attributes_editable?(user), #author
                   test_plan.attributes_editable?(users(:users_001)), #admin
                   test_plan.attributes_editable?(users(:users_003)), #other
                 ]
  end
end
