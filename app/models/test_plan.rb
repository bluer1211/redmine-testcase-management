class TestPlan < ActiveRecord::Base
  belongs_to :user
  belongs_to :issue_status
end
