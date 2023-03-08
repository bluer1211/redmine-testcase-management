require_dependency 'project'

module TestCaseManagement
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_many :test_cases, dependent: :destroy
      has_many :test_case_executions, dependent: :destroy
      has_many :test_plans, dependent: :destroy
    end
  end
end
