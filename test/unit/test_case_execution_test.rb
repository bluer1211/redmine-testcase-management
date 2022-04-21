require File.expand_path("../../test_helper", __FILE__)

class TestCaseExecutionTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issues, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

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
    test_case = TestCase.new
    test_case_execution = TestCaseExecution.new(:id => 100,
                                                :result => true,
                                                :execution_date => "2022-02-28",
                                                :comment => "dummy",
                                                :project => projects(:projects_001),
                                                :user => users(:users_001),
                                                :test_plan => test_plan,
                                                :test_case => test_case,
                                                :issue => issues(:issues_001))
    assert_save test_case_execution
    assert test_case_execution.destroy
  end

  def test_destroy
    TestCaseExecution.find(1).destroy
    assert_nil TestCaseExecution.find_by_id(1)
  end

  def test_destroying_a_deleted_test_case_execution_should_not_raise_an_error
    test_case_execution = TestCaseExecution.find(1)
    TestCaseExecution.find(1).destroy

    assert_nothing_raised do
      assert_no_difference 'TestCaseExecution.count' do
        test_case_execution.destroy
      end
      assert test_case_execution.destroyed?
    end
  end

  def test_destroying_a_stale_test_case_execution_should_not_raise_an_error
    test_case_execution = TestCaseExecution.find(1)
    TestCaseExecution.find(1).update! :comment => "Updated"

    assert_nothing_raised do
      assert_difference 'TestCaseExecution.count', -1 do
        test_case_execution.destroy
      end
      assert test_case_execution.destroyed?
    end
  end

  def test_fixture
    test_case_execution = test_case_executions(:test_case_executions_001)
    assert_equal 1, test_case_execution.id
    assert_equal "Comment 1", test_case_execution.comment
    assert_equal "2022-02-09 15:00:00 UTC", test_case_execution.execution_date.to_s
    assert_equal users(:users_002), test_case_execution.user
    assert_equal issues(:issues_001), test_case_execution.issue
    assert_equal test_plans(:test_plans_003), test_case_execution.test_plan
  end

  def test_not_unique
    test_plan = test_plans(:test_plans_001)
    test_case = test_cases(:test_cases_001)
    test_case_execution = TestCaseExecution.new(:id => test_case_executions(:test_case_executions_001).id,
                                                :result => true,
                                                :comment => "dummy",
                                                :execution_date => "2022-02-28",
                                                :project => test_plan.project,
                                                :user => users(:users_002),
                                                :test_plan => test_plan,
                                                :test_case => test_case,
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
                                   :project => projects(:projects_001),
                                   :user => users(:users_001),
                                   :test_case => TestCase.new,
                                   :execution_date => Time.now.strftime("%F"),
                                   :test_plan => TestPlan.new)
    # the default value of result is false
    assert_equal [false, false],
                 [object.result, object.invalid?]
    assert_equal [], object.errors[:result]
  end

  def test_missing_user
    object = TestCaseExecution.new(:result => false,
                                   :comment => "dummy",
                                   :project => projects(:projects_001),
                                   :test_case => TestCase.new,
                                   :test_plan => TestPlan.new)
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:user]
  end

  def test_missing_comment
    object = TestCaseExecution.new(:result => false,
                                   :project => projects(:projects_001),
                                   :user => users(:users_001),
                                   :test_case => TestCase.new,
                                   :execution_date => Time.now.strftime("%F"),
                                   :test_plan => TestPlan.new)
    assert object.valid?
  end

  def test_missing_execution_date
    object = TestCaseExecution.new(:result => false,
                                   :project => projects(:projects_001),
                                   :user => users(:users_001),
                                   :test_case => TestCase.new,
                                   :test_plan => TestPlan.new,
                                   :comment => "dummy")
    assert_equal true, object.invalid?
    assert_equal ["cannot be blank"], object.errors[:execution_date]
  end

  # Test Relation
  def test_empty_association
    test_case_execution = TestCaseExecution.new
    assert_nil test_case_execution.user
    assert_nil test_case_execution.project
    assert_nil test_case_execution.issue
    assert_nil test_case_execution.execution_date
    assert_nil test_case_execution.test_plan
    assert_nil test_case_execution.test_case
  end

  def test_association
    test_case_execution = test_case_executions(:test_case_executions_001)
    assert_equal issues(:issues_001), test_case_execution.issue
    assert_equal users(:users_002), test_case_execution.user
    assert_equal test_cases(:test_cases_002), test_case_execution.test_case
    # T.B.D.
    #assert_equal 2, test_case_execution.project.id
  end

  def test_no_issue
    test_case_execution = test_case_executions(:test_case_executions_002)
    assert_nil test_case_execution.issue
  end

  # permissions

  def assert_visibility_match(user, test_case_executions)
    assert_equal TestCaseExecution.all.select {|test_case_execution| test_case_execution.visible?(user)}.collect(&:id).sort,
                 test_case_executions.collect(&:id).sort
  end

  def test_visible_scope_for_anonymous
    # Anonymous user should see test_case_executions of public projects only
    test_case_executions = TestCaseExecution.visible(User.anonymous).to_a
    assert test_case_executions.any?
    assert_nil test_case_executions.detect {|test_case_execution| !test_case_execution.project.is_public?}
    assert_visibility_match User.anonymous, test_case_executions
  end

  def test_visible_scope_for_anonymous_without_view_issues_permissions
    # Anonymous user should not see test_case_executions without permission
    Role.anonymous.remove_permission!(:view_issues)
    test_case_executions = TestCaseExecution.visible(User.anonymous).to_a
    assert test_case_executions.empty?
    assert_visibility_match User.anonymous, test_case_executions
  end

  def test_visible_scope_for_anonymous_without_view_issues_permissions_and_membership
    Role.anonymous.remove_permission!(:view_issues)
    Member.create!(:project_id => 3, :principal => Group.anonymous, :role_ids => [2])

    test_case_executions = TestCaseExecution.visible(User.anonymous).all
    assert_equal [true, [3]],
                 [test_case_executions.any?,
                  test_case_executions.map(&:project_id).uniq.sort]
    assert_visibility_match User.anonymous, test_case_executions
  end

  def test_visible_scope_for_non_member
    user = User.find(9)
    assert user.projects.empty?
    # Non member user should see test_case_executions of public projects only
    test_case_executions = TestCaseExecution.visible(user).to_a
    assert_equal [true, nil],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| !test_case_execution.project.is_public?}]
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_non_member_with_own_test_case_execution_visibility
    Role.non_member.update! :issues_visibility => "own"
    user = User.find(9)
    TestCaseExecution.create!(project_id: 3, comment: "test case execution by non member",
                              result: true, test_plan_id: 3, test_case_id: 3,
                              user_id: user.id, execution_date: DateTime.new)

    test_case_executions = TestCaseExecution.visible(user).to_a
    assert_equal [true, nil],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| test_case_execution.user != user}]
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_non_member_without_view_test_case_execution_permissions
    # Non member user should not see test_case_executions without permission
    Role.non_member.remove_permission!(:view_issues)
    user = User.find(9)
    assert user.projects.empty?
    test_case_executions = TestCaseExecution.visible(user).to_a
    assert test_case_executions.empty?
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_non_member_without_view_test_case_executions_permissions_and_membership
    Role.non_member.remove_permission!(:view_issues)
    Member.create!(:project_id => 3, :principal => Group.non_member, :role_ids => [2])
    user = User.find(9)

    test_case_executions = TestCaseExecution.visible(user).all
    assert test_case_executions.any?
    assert_equal [3], test_case_executions.map(&:project_id).uniq.sort
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_member
    user = User.find(9)
    # User should see test_case_executions of projects for which user has view_issues permissions only
    Role.non_member.remove_permission!(:view_issues)
    Member.create!(:principal => user, :project_id => 3, :role_ids => [2])
    test_case_executions = TestCaseExecution.visible(user).to_a
    assert_equal [true, nil],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| test_case_execution.project_id != 3}]
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_member_with_default_test_case_execution_visibility
    role = Role.generate!(:permissions => [:view_project, :view_issues],
                          :issues_visibility => "default")
    user = User.generate!
    # Use private project
    project = Project.find(5)
    User.add_to_project(user, project, [role])
    # user (default issues visibility) can see test case execution under private project
    test_case_executions = TestCaseExecution.visible(user).to_a
    assert_equal [true, test_case_executions(:test_case_executions_004)],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| test_case_execution.project_id == project.id}]
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
    Role.non_member.add_permission!(:view_issues)
    Role.find(1).remove_permission!(:view_issues)
    user = User.find(2)

    assert_equal [0, false],
                 [TestCaseExecution.where(:project_id => 1).visible(user).count,
                  TestCaseExecution.where(:project_id => 1).first.visible?(user)]
  end

  def test_visible_scope_with_custom_non_member_role_having_restricted_permission
    role = Role.generate!(:permissions => [:view_project])
    assert Role.non_member.has_permission?(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 1, :roles => [role])

    test_case_executions = TestCaseExecution.visible(user).to_a
    assert_equal [true, nil],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| test_case_execution.project_id == 1}]
  end

  def test_visible_scope_with_custom_non_member_role_having_extended_permission
    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => 3, :roles => [role])

    test_case_executions = TestCaseExecution.visible(user).to_a
    assert test_case_executions.any?
    assert_not_nil test_case_executions.detect {|test_case_execution| test_case_execution.project_id == 3}
  end

  def test_visible_scope_should_not_consider_roles_without_view_issues_permission
    user = User.generate!
    role1 = Role.generate!
    role1.remove_permission! :view_issues
    role1.save!
    role2 = Role.generate!
    role2.remove_permission! :view_issues
    role2.save!
    User.add_to_project(user, Project.find(3), [role1, role2])

    test_case_executions = TestCaseExecution.where(:project_id => 3).visible(user).to_a
    assert_not test_case_executions.any?

    role2.add_permission! :view_issues
    role2.save!
    user.reload

    test_case_executions = TestCaseExecution.where(:project_id => 3).visible(user).to_a
    assert test_case_executions.any?
  end

  def test_visible_scope_for_admin
    user = User.find(1)
    user.members.each(&:destroy)
    assert user.projects.empty?
    test_case_executions = TestCaseExecution.visible(user).to_a
    # Admin should see test_case_executions on private projects that admin does not belong to
    assert_equal [true, test_case_executions(:test_case_executions_004)],
                 [test_case_executions.any?,
                  test_case_executions.detect {|test_case_execution| !test_case_execution.project.is_public?}]
    assert_visibility_match user, test_case_executions
  end

  def test_visible_scope_with_project
    project = Project.find(1)
    test_case_executions = TestCaseExecution.visible(User.find(2), :project => project).to_a
    projects = test_case_executions.collect(&:project).uniq
    assert_equal [1, project],
                 [projects.size, projects.first]
  end

  def test_visible_scope_with_project_and_subprojects
    project = Project.find(1)
    test_case_executions = TestCaseExecution.visible(User.find(2), :project => project, :with_subprojects => true).to_a
    projects = test_case_executions.collect(&:project).uniq
    assert [true, []],
           [projects.size > 1,
            projects.select {|p| !p.is_or_is_descendant_of?(project)}]
  end

  def test_visible_scope_with_unsaved_user_should_not_raise_an_error
    user = User.new
    assert_nothing_raised do
      TestCaseExecution.visible(user).to_a
    end
  end

  def test_test_case_execution_should_be_readonly_on_closed_project
    test_case_execution = TestCaseExecution.find(1)
    user = User.find(1)

    assert_equal [true, true, true],
                 [test_case_execution.visible?(user),
                  test_case_execution.editable?(user),
                  test_case_execution.deletable?(user)]

    test_case_execution.project.close
    test_case_execution.reload

    assert_equal [true, false, false],
                 [test_case_execution.visible?(user),
                  test_case_execution.editable?(user),
                  test_case_execution.deletable?(user)]
  end

  def test_test_plan_should_editable_by_author
    Role.all.each do |role|
      role.remove_permission! :edit_issues
      role.add_permission! :edit_own_issues
    end

    test_case_execution = test_case_executions(:test_case_executions_001)
    user = users(:users_002)

    assert_equal user, test_case_execution.user
    assert_equal [true, true, false],
                 [
                   test_case_execution.attributes_editable?(user), #author
                   test_case_execution.attributes_editable?(users(:users_001)), #admin
                   test_case_execution.attributes_editable?(users(:users_003)), #other
                 ]
  end

  def test_editable_scope_for_member
    test_case_execution = test_case_executions(:test_case_executions_001)

    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => test_case_execution.project_id, :roles => [role])

    assert_not test_case_execution.editable?(user)

    role.add_permission!(:edit_issues)
    test_case_execution.reload
    user.reload
    assert test_case_execution.editable?(user)
  end

  def test_deletable_scope_for_member
    test_case_execution = test_case_executions(:test_case_executions_001)

    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => test_case_execution.project_id, :roles => [role])

    assert_not test_case_execution.deletable?(user)

    role.add_permission!(:delete_issues)
    test_case_execution.reload
    user.reload
    assert test_case_execution.deletable?(user)
  end

  def test_attachments_visible_scope_for_member
    test_case_execution = test_case_executions(:test_case_executions_001)

    role = Role.generate!
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => test_case_execution.project_id, :roles => [role])

    assert_not test_case_execution.attachments_visible?(user)

    role.add_permission!(:view_issues)
    test_case_execution.reload
    user.reload
    assert test_case_execution.attachments_visible?(user)
  end

  def test_attachments_editable_scope_for_member
    test_case_execution = test_case_executions(:test_case_executions_001)

    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => test_case_execution.project_id, :roles => [role])

    assert_not test_case_execution.attachments_editable?(user)

    role.add_permission!(:edit_issues)
    test_case_execution.reload
    user.reload
    assert test_case_execution.attachments_editable?(user)
  end

  def test_attachments_deletable_scope_for_member
    test_case_execution = test_case_executions(:test_case_executions_001)

    role = Role.generate!(:permissions => [:view_project, :view_issues])
    Role.non_member.remove_permission!(:view_issues)
    user = User.generate!
    Member.create!(:principal => Group.non_member, :project_id => test_case_execution.project_id, :roles => [role])

    assert_not test_case_execution.attachments_deletable?(user)

    role.add_permission!(:delete_issues)
    test_case_execution.reload
    user.reload
    assert test_case_execution.attachments_deletable?(user)
  end

  def test_ownable_user
    test_case_execution = test_case_executions(:test_case_executions_001)
    validity = {}
    visibility = {}
    Role.non_member.remove_permission!(:view_issues)

    test_case_execution.user = User.find(1) # admin
    validity[:admin] = test_case_execution.valid?
    visibility[:admin] = test_case_execution.visible?(test_case_execution.user)

    permitted_role = Role.generate!
    permitted_role.add_permission! :view_issues
    permitted_role.save!
    unpermitted_role = Role.generate!
    unpermitted_role.remove_permission! :view_issues
    unpermitted_role.save!

    permitted_member = User.generate!
    User.add_to_project(permitted_member, test_case_execution.project, [permitted_role, unpermitted_role])
    test_case_execution.user = permitted_member
    validity[:permitted_member] = test_case_execution.valid?
    visibility[:permitted_member] = test_case_execution.visible?(test_case_execution.user)

    unpermitted_member = User.generate!
    User.add_to_project(unpermitted_member, test_case_execution.project, [unpermitted_role])
    test_case_execution.user = unpermitted_member
    validity[:unpermitted_member] = test_case_execution.valid?
    visibility[:unpermitted_member] = test_case_execution.visible?(test_case_execution.user)

    non_member = User.generate!
    test_case_execution.user = non_member
    validity[:non_member] = test_case_execution.valid?
    visibility[:non_member] = test_case_execution.visible?(test_case_execution.user)

    assert_equal visibility, validity
    assert_equal({ admin: true,
                   permitted_member: true,
                   unpermitted_member: false,
                   non_member: false },
                 validity)
  end
end
