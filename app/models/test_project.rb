class TestProject < ActiveRecord::Base
  belongs_to :project
  has_many :test_plans, dependent: :destroy
  has_many :test_case_executions

  validates_associated :test_plans
end
