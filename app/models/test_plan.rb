class TestPlan < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue_status
  has_many :test_case_executions
  has_many :test_cases, dependent: :destroy

  validates :name, presence: true
  validates :user, presence: true
  validates :issue_status, presence: true

  validates_associated :test_cases
  validates_associated :test_case_executions
end
