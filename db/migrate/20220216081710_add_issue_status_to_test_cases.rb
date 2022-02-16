class AddIssueStatusToTestCases < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_cases, :issue_status, foreign_key: true
  end
end
