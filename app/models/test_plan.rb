class TestPlan < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue_status
  belongs_to :project
  has_many :test_case_executions, dependent: :destroy
  has_many :test_cases, dependent: :destroy

  validates :name, presence: true
  validates :user, presence: true
  validates :issue_status, presence: true

  validates_associated :test_cases
  validates_associated :test_case_executions

  validates_length_of :name, :maximum => 255

  def editable?
    true
  end

  def deletable?
    true
  end
end
