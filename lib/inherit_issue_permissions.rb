module TestCaseManagement
  module InheritIssuePermissions
    def issues_visible?(user=User.current)
      user.allowed_to?(:view_issues, project) do |role, allowed_user|
        if allowed_user.logged?
          case role.issues_visibility
          when "all"
            true
          when "default"
            # NOTE: issues_visibility="default" means "allow only showing public (non private) issues.
            # This property is meaningful for issues visibility because the behavior should be changed for "private" issue,
            # but for test plan, test case, and test case execution, there are no such a state.
            # Thus, it is no need to distinct this state.
            true
          when "own"
            self.user == allowed_user
          else
            false
          end
        else
          role.permissions_all_trackers?(:view_issues)
        end
      end
    end

    def issue_editable?(user=User.current)
      user_permission?(user, :edit_issues) || (
        user_permission?(user, :edit_own_issues) && self.user == user
      )
    end

    def editable?(user=User.current)
      attributes_editable?(user)
    end

    def ownable_users
      return [] if project.nil?

      users = project.assignable_users.to_a
      users.uniq.sort
    end

    def allowed_target_projects(user=User.current, scope=nil)
      issue = Issue.new
      issue.project = project
      issue.allowed_target_projects(user, scope)
    end

    private

    def user_permission?(user, permission)
      if project && !project.active?
        perm = Redmine::AccessControl.permission(permission)
        return false unless perm && perm.read?
      end

      if user.admin?
        true
      else
        user.roles_for_project(project).any? do |role|
          role.has_permission?(permission)
        end
      end
    end

    def owned_only_by_visible_user
      return true unless user
      errors.add(:user, "Unownable User #{user.id} for #{self.class.name} #{id}") unless visible?(user)
    end

    module_function

    def self.visible_condition(user, permission, options={})
      Project.allowed_to_condition(user, permission, options) do |role, allowed_user|
        if allowed_user.id && allowed_user.logged?
          "1=1"
        else
          "projects.is_public = (1=1)"
        end
      end
    end

    def self.issue_visible_condition(user, options={})
      Project.allowed_to_condition(user, :view_issues, options) do |role, allowed_user|
        sql =
          if allowed_user.id && allowed_user.logged?
            case role.issues_visibility
            when "all"
              "1=1"
            when "default"
              # NOTE: In test case management, the private state is not used.
              # Thus it should be same as all. See visible? method in this module.
              "1=1"
            when "own"
              "user_id = #{allowed_user.id}"
            else
              "1=0"
            end
          else
            "projects.is_public = (1=1)"
          end
        unless role.permissions_all_trackers?(:view_issues)
          sql = "1=0"
        end
        sql
      end
    end
  end
end
