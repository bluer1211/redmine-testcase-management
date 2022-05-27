require File.expand_path("../../test_helper", __FILE__)

class TestCaseTest < ActiveSupport::TestCase

  fixtures :projects, :users, :members, :member_roles, :roles, :issue_statuses,
           :groups_users, :trackers, :projects_trackers, :enabled_modules
  fixtures :test_plans, :test_cases, :test_case_executions, :test_case_test_plans

  class BasicTest < self
    def setup
      activate_module_for_projects
      Role.all.each do |role|
        role.add_permission! :view_test_cases
      end
    end

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

    def test_destroy
      TestCase.find(1).destroy
      assert_nil TestCase.find_by_id(1)
    end

    def test_destroying_a_deleted_test_case_should_not_raise_an_error
      test_case = TestCase.find(1)
      TestCase.find(1).destroy

      assert_nothing_raised do
        assert_no_difference 'TestCase.count' do
          test_case.destroy
        end
        assert test_case.destroyed?
      end
    end

    def test_destroying_a_stale_test_case_should_not_raise_an_error
      test_case = TestCase.find(1)
      test_case.update! name: "Updated"

      assert_nothing_raised do
        assert_difference 'TestCase.count', -1 do
          test_case.destroy
        end
        assert test_case.destroyed?
      end
    end

    def test_fixture
      test_case = test_cases(:test_cases_001)
      assert_equal 1, test_case.id
      assert_equal "Test Case 1 (No test case execution)", test_case.name
      assert_equal "Scenario 1", test_case.scenario
      assert_equal "Expected 1", test_case.expected
      assert_equal "Debian GNU/Linux", test_case.environment
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

    def test_missing_project
      object = TestCase.new(:name => "name",
                            :scenario => "dummy",
                            :expected => "dummy",
                            :user => users(:users_001),
                            :environment => "dummy")
      assert_equal true, object.invalid?
      assert_equal ["cannot be blank"], object.errors[:project]
    end

    def test_missing_name
      object = TestCase.new(:project_id => 1,
                            :scenario => "dummy",
                            :expected => "dummy",
                            :user => users(:users_001),
                            :environment => "dummy")
      assert_equal true, object.invalid?
      assert_equal ["cannot be blank"], object.errors[:name]
    end

    def test_missing_scenario
      object = TestCase.new(:project_id => 1,
                            :name => "dummy",
                            :expected => "dummy",
                            :user => users(:users_001),
                            :environment => "dummy")
      assert_equal true, object.invalid?
      assert_equal ["cannot be blank"], object.errors[:scenario]
    end

    def test_missing_expected
      object = TestCase.new(:project_id => 1,
                            :name => "dummy",
                            :scenario => "dummy",
                            :user => users(:users_001),
                            :environment => "dummy")
      assert_equal true, object.invalid?
      assert_equal ["cannot be blank"], object.errors[:expected]
    end

    def test_missing_user
      object = TestCase.new(:project_id => 1,
                            :name => "dummy",
                            :scenario => "dummy",
                            :expected => "dummy",
                            :environment => "dummy")
      assert_equal true, object.invalid?
      assert_equal ["cannot be blank"], object.errors[:user]
    end

    def test_missing_environment
      # environment is optional
      object = TestCase.new(:project_id => 1,
                            :name => "dummy",
                            :scenario => "dummy",
                            :expected => "dummy",
                            :user => users(:users_001))
      assert_equal true, object.valid?
      assert_equal [], object.errors[:environment]
    end

    # Test Relations

    def test_association
      test_case = TestCase.new
      assert_nil test_case.user
      assert_nil test_case.project
      assert_not test_case.test_plans.any?
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
                                                               :project => test_case.project,
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
                                                               :project => test_case.project,
                                                               :user => users(:users_001),
                                                               :test_case => test_case,
                                                               :test_plan => TestPlan.new,
                                                               :execution_date => Time.now.strftime("%F"))
      assert_equal [true, true],
                   [test_case_execution.valid?, test_case.valid?]
      assert_save test_case
      assert_equal 1, test_cases(:test_cases_001).test_case_executions.size
    end

    # permissions

    def assert_visibility_match(user, test_cases)
      assert_equal TestCase.all.select {|test_case| test_case.visible?(user)}.collect(&:id).sort,
                   test_cases.collect(&:id).sort
    end

    def test_visible_scope_for_anonymous
      # Anonymous user should see test_cases of public projects only
      test_cases = TestCase.visible(User.anonymous).to_a
      assert_equal [true, nil],
                   [test_cases.any?,
                    test_cases.detect {|test_case| !test_case.project.is_public?}]
      assert_visibility_match User.anonymous, test_cases
    end

    def test_visible_scope_for_anonymous_without_view_issues_permissions
      # Anonymous user should not see test_cases without permission
      Role.anonymous.remove_permission! :view_issues
      test_cases = TestCase.visible(User.anonymous).to_a
      assert test_cases.empty?
      assert_visibility_match User.anonymous, test_cases
    end

    def test_visible_scope_for_anonymous_without_view_issues_permissions_and_membership
      Role.anonymous.remove_permission! :view_issues
      Member.create!(:project_id => 3, :principal => Group.anonymous, :role_ids => [2])

      test_cases = TestCase.visible(User.anonymous).all
      assert_equal [true, [3]],
                   [test_cases.any?,
                    test_cases.map(&:project_id).uniq.sort]
      assert_visibility_match User.anonymous, test_cases
    end

    def test_visible_scope_for_non_member
      user = User.find(9)
      assert user.projects.empty?
      # Non member user should see test_cases of public projects only
      test_cases = TestCase.visible(user).to_a
      assert_equal [true, nil],
                   [test_cases.any?,
                    test_cases.detect {|test_case| !test_case.project.is_public?}]
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_for_non_member_without_view_test_case_permissions
      # Non member user should not see test_cases without permission
      Role.non_member.remove_permission! :view_issues
      user = User.find(9)
      assert user.projects.empty?
      test_cases = TestCase.visible(user).to_a
      assert test_cases.empty?
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_for_non_member_without_view_test_cases_permissions_and_membership
      Role.non_member.remove_permission! :view_issues
      Member.create!(:project_id => 3, :principal => Group.non_member, :role_ids => [2])
      user = User.find(9)

      test_cases = TestCase.visible(user).all
      assert test_cases.any?
      assert_equal [3], test_cases.map(&:project_id).uniq.sort
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_for_member
      user = User.find(9)
      # User should see test_cases of projects for which user has view_issues permissions only
      Role.non_member.remove_permission! :view_issues
      Member.create!(:principal => user, :project_id => 3, :role_ids => [2])
      test_cases = TestCase.visible(user).to_a
      assert_equal [true, nil],
                   [test_cases.any?,
                    test_cases.detect {|test_case| test_case.project_id != 3}]
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_for_member_with_default_test_case_visibility
      role = Role.generate!(:permissions => [:view_project, :view_issues, :view_test_cases],
                            :issues_visibility => "default")
      user = User.generate!
      # Use private project
      project = Project.find(5)
      User.add_to_project(user, project, [role])
      # user (default issues visibility) can see test case under private project
      test_cases = TestCase.visible(user).to_a
      assert_equal [true, test_cases(:test_cases_004)],
                   [test_cases.any?,
                    test_cases.detect {|test_case| test_case.project_id == project.id}]
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_for_member_without_view_issues_permission_and_non_member_role_having_the_permission
      Role.non_member.add_permission! :view_issues
      Role.find(1).remove_permission! :view_issues
      user = User.find(2)

      assert_equal [0, false],
                   [TestCase.where(:project_id => 1).visible(user).count,
                    TestCase.where(:project_id => 1).first.visible?(user)]
    end

    def test_visible_scope_with_custom_non_member_role
      Role.non_member.remove_permission! :view_test_cases
      user = User.generate!

      test_cases = TestCase.visible(user).to_a
      assert_equal 0, test_cases.size

      Role.non_member.add_permission! :view_issues
      Role.non_member.add_permission! :view_test_cases
      user.reload

      test_cases = TestCase.visible(user).to_a
      assert_not_equal 0, test_cases.size
    end

    def test_visible_scope_with_custom_role_with_permission
      Role.non_member.remove_permission! :view_test_cases
      user = User.generate!

      test_cases = TestCase.visible(user).to_a
      assert_equal 0, test_cases.size

      role = Role.generate!(:permissions => [:view_project, :view_issues, :view_test_cases])
      Member.create!(:principal => Group.non_member, :project_id => 3, :roles => [role])
      user.reload

      test_cases = TestCase.visible(user).to_a
      assert_not_equal 0, test_cases.size
    end

    def test_visible_scope_should_not_consider_roles_without_view_issues_permission
      user = User.generate!
      role1 = Role.generate!
      role1.add_permission! :view_test_cases
      role1.remove_permission! :view_issues
      role1.save!
      role2 = Role.generate!
      role2.add_permission! :view_test_cases
      role2.remove_permission! :view_issues
      role2.save!
      User.add_to_project(user, Project.find(3), [role1, role2])

      test_cases = TestCase.where(:project_id => 3).visible(user).to_a
      assert_not test_cases.any?

      role2.add_permission! :view_issues
      role2.save!
      user.reload

      test_cases = TestCase.where(:project_id => 3).visible(user).to_a
      assert test_cases.any?
    end

    def test_visible_scope_for_admin
      user = User.find(1)
      user.members.each(&:destroy)
      assert user.projects.empty?
      test_cases = TestCase.visible(user).to_a
      # Admin should see test_cases on private projects that admin does not belong to
      assert_equal [true, test_cases(:test_cases_004)],
                   [test_cases.any?,
                    test_cases.detect {|test_case| !test_case.project.is_public?}]
      assert_visibility_match user, test_cases
    end

    def test_visible_scope_with_project
      project = Project.find(1)
      generate_user_with_permissions(project, [:view_project, :view_issues, :view_test_cases])
      test_cases = TestCase.visible(@user, :project => project).to_a
      projects = test_cases.collect(&:project).uniq
      assert_equal [1, project],
                   [projects.size, projects.first]
    end

    def test_visible_scope_with_project_and_subprojects
      project = Project.find(1)
      generate_user_with_permissions(project, [:view_project, :view_issues, :view_test_cases])
      test_cases = TestCase.visible(@user, :project => project, :with_subprojects => true).to_a
      projects = test_cases.collect(&:project).uniq
      assert [true, []],
             [projects.size > 1,
              projects.select {|p| !p.is_or_is_descendant_of?(project)}]
    end

    def test_visible_scope_with_unsaved_user_should_not_raise_an_error
      user = User.new
      assert_nothing_raised do
        TestCase.visible(user).to_a
      end
    end

    def test_should_be_readonly_on_closed_project
      test_case = TestCase.find(1)
      generate_user_with_permissions(test_case.project, [:view_project, :view_issues, :view_test_cases, :edit_test_cases, :delete_test_cases])

      assert_equal [true, true, true],
                   [test_case.visible?(@user),
                    test_case.editable?(@user),
                    test_case.deletable?(@user)]

      test_case.project.close
      test_case.reload
      @user.reload

      assert_equal [true, false, false],
                   [test_case.visible?(@user),
                    test_case.editable?(@user),
                    test_case.deletable?(@user)]
    end

    def test_should_editable_with_permission
      test_case = test_cases(:test_cases_001)
      generate_user_with_permissions(test_case.project, [:view_project, :view_issues, :edit_test_cases])
      other = User.generate!

      assert_equal [true, true, false],
                   [
                     test_case.attributes_editable?(users(:users_001)), #admin
                     test_case.attributes_editable?(@user), #member
                     test_case.attributes_editable?(other), #other
                   ]
    end

    def test_should_readonly_for_anonymous_by_defaultXXX
      test_case = TestCase.find(1)
      assert_equal [true, false, false],
                   [test_case.visible?(User.anonymous),
                    test_case.editable?(User.anonymous),
                    test_case.deletable?(User.anonymous)]
    end

    def test_visible_scope_for_member
      test_case = test_cases(:test_cases_001)

      generate_user_with_permissions(test_case.project, [:view_project])
      assert_equal [false, false],
                   [test_case.visible?(@user),
                    test_case.attachments_visible?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues])
      assert_equal [false, false],
                   [test_case.visible?(@user),
                    test_case.attachments_visible?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_test_cases])
      assert_equal [false, false],
                   [test_case.visible?(@user),
                    test_case.attachments_visible?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues, :view_test_cases])
      assert_equal [true, true],
                   [test_case.visible?(@user),
                    test_case.attachments_visible?(@user)]
    end

    def test_editable_scope_for_member
      test_case = test_cases(:test_cases_001)

      generate_user_with_permissions(test_case.project, [:view_project])
      assert_equal [false, false],
                   [test_case.editable?(@user),
                    test_case.attachments_editable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues])
      assert_equal [false, false],
                   [test_case.editable?(@user),
                    test_case.attachments_editable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :edit_test_cases])
      assert_equal [true, true],
                   [test_case.editable?(@user),
                    test_case.attachments_editable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues, :edit_test_cases])
      assert_equal [true, true],
                   [test_case.editable?(@user),
                    test_case.attachments_editable?(@user)]
    end

    def test_deletable_scope_for_member
      test_case = test_cases(:test_cases_001)

      generate_user_with_permissions(test_case.project, [:view_project])
      assert_equal [false, false],
                   [test_case.deletable?(@user),
                    test_case.attachments_deletable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues])
      assert_equal [false, false],
                   [test_case.deletable?(@user),
                    test_case.attachments_deletable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :delete_test_cases])
      assert_equal [true, true],
                   [test_case.deletable?(@user),
                    test_case.attachments_deletable?(@user)]

      generate_user_with_permissions(test_case.project, [:view_project, :view_issues, :delete_test_cases])
      assert_equal [true, true],
                   [test_case.deletable?(@user),
                    test_case.attachments_deletable?(@user)]
    end

    def test_ownable_user
      test_case = test_cases(:test_cases_001)
      validity = {}
      visibility = {}
      Role.non_member.remove_permission!(:view_issues)

      test_case.user = User.find(1) # admin
      validity[:admin] = test_case.valid?
      visibility[:admin] = test_case.visible?(test_case.user)

      permitted_role = Role.generate!
      permitted_role.add_permission! :view_issues
      permitted_role.add_permission! :view_test_cases
      permitted_role.save!
      unpermitted_role = Role.generate!
      unpermitted_role.remove_permission! :view_issues
      unpermitted_role.save!

      permitted_member = User.generate!
      User.add_to_project(permitted_member, test_case.project, [permitted_role, unpermitted_role])
      test_case.user = permitted_member
      validity[:permitted_member] = test_case.valid?
      visibility[:permitted_member] = test_case.visible?(test_case.user)

      unpermitted_member = User.generate!
      User.add_to_project(unpermitted_member, test_case.project, [unpermitted_role])
      test_case.user = unpermitted_member
      validity[:unpermitted_member] = test_case.valid?
      visibility[:unpermitted_member] = test_case.visible?(test_case.user)

      non_member = User.generate!
      test_case.user = non_member
      validity[:non_member] = test_case.valid?
      visibility[:non_member] = test_case.visible?(test_case.user)

      assert_equal visibility, validity
      assert_equal({ admin: true,
                     permitted_member: true,
                     unpermitted_member: false,
                     non_member: false },
                   validity)
    end
  end

  class LatestExecutionTest < self
    def setup
      TestCaseExecution.destroy_all
      TestCase.destroy_all
      TestPlan.destroy_all

      @test_case = generate_test_case({
        name: "tc1",
      })
      @another_test_case = generate_test_case({
        name: "tc2",
      })

      @test_plan = generate_test_plan({
        name: "tp1",
      })
      @another_test_plan = generate_test_plan({
        name: "tp2",
      })

      @test_plan.test_cases << @test_case
      @test_plan.test_cases << @another_test_case
      @another_test_plan.test_cases << @test_case
      @another_test_plan.test_cases << @another_test_case
    end

    def test_find_with_latest_result
      generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })
      latest_execution_in_plan = generate_test_case_execution({
        result: false,
        execution_date: "2022-04-21",
        test_case: @test_case,
        test_plan: @test_plan,
      })
      latest_execution = generate_test_case_execution({
        result: false,
        execution_date: "2022-04-22",
        test_case: @test_case,
        test_plan: @another_test_plan,
      })

      tc = TestCase.find_with_latest_result(@test_case.id)
      assert_equal latest_execution.id, tc.latest_execution_id

      tc = TestCase.find_with_latest_result(@test_case.id, test_plan: @test_plan)
      assert_equal latest_execution_in_plan.id, tc.latest_execution_id
    end

    def test_count
      generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })
      generate_test_case_execution({
        result: false,
        execution_date: "2022-04-21",
        test_case: @test_case,
        test_plan: @another_test_plan,
      })

      # note: pluck(:id) may produce too many results with duplicated id. why?
      assert_equal TestCase.all.collect(&:id).sort,
                   TestCase.with_latest_result.collect(&:id).sort
      assert_equal @test_plan.test_cases.collect(&:id).sort,
                   TestCase.with_latest_result(@test_plan).collect(&:id).sort
    end

    def test_across_test_plans
      execution = generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })
      generate_test_case_execution({
        result: false,
        execution_date: "2022-04-19",
        test_case: @test_case,
        test_plan: @test_plan,
      })

      tc = TestCase.find_with_latest_result(@test_case.id)
      assert_equal([true, Time.parse("2022-04-20"), execution.id],
                   [tc.latest_result, tc.latest_execution_date, tc.latest_execution_id])

      execution = generate_test_case_execution({
        result: false,
        execution_date: "2022-04-21",
        test_case: @test_case,
        test_plan: @another_test_plan,
      })
      generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @another_test_plan,
      })

      tc = TestCase.find_with_latest_result(@test_case.id)
      assert_equal([false, Time.parse("2022-04-21"), execution.id],
                   [tc.latest_result, tc.latest_execution_date, tc.latest_execution_id])
    end

    def test_with_same_execution_date
      generate_test_case_execution({
        result: false,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })
      execution = generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })

      tc = TestCase.find_with_latest_result(@test_case.id)
      assert_equal([true, Time.parse("2022-04-20"), execution.id],
                   [tc.latest_result, tc.latest_execution_date, tc.latest_execution_id])
    end

    def test_with_test_plan
      generate_test_case_execution({
        result: false,
        execution_date: "2022-04-21",
        test_case: @test_case,
        test_plan: @another_test_plan,
      })
      execution = generate_test_case_execution({
        result: true,
        execution_date: "2022-04-20",
        test_case: @test_case,
        test_plan: @test_plan,
      })

      tc = TestCase.find_with_latest_result(@test_case.id, test_plan: @test_plan)
      assert_equal([true, Time.parse("2022-04-20"), execution.id],
                   [tc.latest_result, tc.latest_execution_date, tc.latest_execution_id])
    end
  end
end
