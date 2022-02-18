class TestCase < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue_status
  has_many :test_case_executions

  validates :name, presence: true
  validates :scenario, presence: true
  validates :expected, presence: true
  validates :user, presence: true
  validates :environment, presence: true
  validates :issue_status, presence: true
end
