class TestProject < ActiveRecord::Base
  belongs_to :project, foreign_key: true
  has_many :test_plans, dependent: :destroy
  has_many :test_case_executions
  has_many :test_cases

  validates_associated :test_plans
end
