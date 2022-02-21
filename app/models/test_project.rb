class TestProject < ActiveRecord::Base
  belongs_to :project
  has_many :test_plans, dependent: :destroy

  validates_associated :test_plans
end
