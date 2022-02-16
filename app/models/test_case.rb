class TestCase < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :issue_status
end
