class TestCase < ActiveRecord::Base
  belongs_to :user
  belongs_to :test_project
  belongs_to :issue_status
  belongs_to :test_plan
  has_many :test_case_executions
  has_many :test_case_attachments

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true
  validates :issue_status, presence: true

  validates_associated :test_case_executions
end
