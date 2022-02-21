require_dependency 'project'

module TestCaseManagement
  module ProjectPatch
    extend ActiveSupport::Concern

    included do
      has_one :test_project, dependent: :destroy
    end
  end
end
ActiveSupport::Reloader.to_prepare do
  unless Project.included_modules.include?(TestCaseManagement::ProjectPatch)
    Project.send(:include, TestCaseManagement::ProjectPatch)
  end
end
