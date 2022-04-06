class TestCase < ActiveRecord::Base
  include Redmine::SafeAttributes
  include TestCaseManagement::InheritIssuePermissions

  belongs_to :user
  belongs_to :project
  has_many :test_case_test_plans, dependent: :destroy
  has_many :test_plans, through: :test_case_test_plans
  has_many :test_case_executions, dependent: :destroy
  acts_as_attachable

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true
  validates :project, presence: true

  validates_associated :test_case_executions

  safe_attributes(
    "project_id'",
    "user_id",
    "name",
    "environment",
    "scenario",
    "expected",
    :if => lambda {|test_case, user| test_case.new_record? || test_case.attributes_editable?(user)})

  def safe_attribute_names(user=nil)
    names = super
    names << "project_id" if new_record?
    names
  end

  def safe_attributes=(attrs, user=User.current)
    if attrs.respond_to?(:to_unsafe_hash)
      attrs = attrs.to_unsafe_hash
    end

    @attributes_set_by = user
    return unless attrs.is_a?(Hash)

    attrs = attrs.deep_dup

    if (given_project = attrs.delete("project_id")) && safe_attribute?("project_id")
      if given_project.is_a?(String) && !/^\d*$/.match?(given_project)
        given_project_id = Project.find_by_identifier(given_project).try(:id)
      else
        given_project_id = given_project.to_i
      end
      if allowed_target_projects(user).where(:id => given_project_id).exists?
        self.project_id = given_project_id
      end
    end

    assign_attributes attrs
  end

  def assign_attributes(new_attributes, *args)
    return if new_attributes.nil?

    attrs = new_attributes.dup
    attrs.stringify_keys!

    %w(project project_id).each do |attr|
      if attrs.has_key?(attr)
        send "#{attr}=", attrs.delete(attr)
      end
    end
    super attrs, *args
  end

  def attributes=(new_attributes)
    assign_attributes new_attributes
  end

  scope :visible, (lambda do |*args|
    joins(:project).
    where(TestCaseManagement::InheritIssuePermissions.visible_condition(args.shift || User.current, *args))
  end)

  #self.test_case_executions.order("execution_date desc").first
  has_one :latest_result, -> {
    where(<<~SQL
    NOT EXISTS (
      SELECT 1 FROM test_case_executions AS tce
      WHERE test_case_executions.execution_date < tce.execution_date
      AND test_case_executions.test_case_id = tce.test_case_id
      AND tce.execution_date IS NOT NULL
    )
SQL
         )
  }, class_name: :TestCaseExecution

  has_one :execution_date, -> {
    where(<<~SQL
    NOT EXISTS (
      SELECT 1 FROM test_case_executions AS tce
      WHERE test_case_executions.execution_date < tce.execution_date
      AND test_case_executions.test_case_id = tce.test_case_id
      AND tce.execution_date IS NOT NULL
    )
SQL
         )
  }, class_name: :TestCaseExecution

  def attachments_visible?(user=User.current)
    visible?(user)
  end

  def attachments_editable?(user=User.current)
    editable?(user)
  end

  def attachments_deletable?(user=User.current)
    deletable?(user)
  end

  # Workaround for functional tests.
  # This should be removed after we completely migrate to test_plan-independent design.
  def test_plan
    test_plans.first
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
end
