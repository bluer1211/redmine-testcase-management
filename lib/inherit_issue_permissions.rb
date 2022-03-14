module TestCaseManagement
  module InheritIssuePermissions
    def editable?(user=User.current)
      attributes_editable?(user)
    end

    def attributes_editable?(user=User.current)
      user_permission?(user, :edit_issues) || (
        user_permission?(user, :edit_own_issues) && self.user == user
      )
    end

    def deletable?(user=User.current)
      user_permission?(user, :delete_issues)
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
  end
end
