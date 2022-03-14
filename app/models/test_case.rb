class TestCase < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :test_plan
  has_many :test_case_executions, dependent: :destroy
  acts_as_attachable

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true

  validates_associated :test_case_executions

  def editable?(user=User.current)
    attributes_editable?(user)
  end

  # Inherit issues permission for now.
  def attributes_editable?(user=User.current)
    user_permission?(user, :edit_issues) || (
      user_permission?(user, :edit_own_issues) && self.user == user
    )
  end

  def deletable?(user=User.current)
    user_permission?(user, :delete_issues)
  end

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_editable?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    true
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
