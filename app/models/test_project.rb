class TestProject < ActiveRecord::Base
  belongs_to :project
  has_many :test_plans, dependent: :destroy
  has_many :test_case_executions, dependent: :destroy
  has_many :test_cases, dependent: :destroy

  validates_associated :test_plans
end
