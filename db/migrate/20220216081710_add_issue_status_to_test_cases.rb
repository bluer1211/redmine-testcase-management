class AddIssueStatusToTestCases < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_cases, :issue_status, foreign_key: true, type: :integer
  end
end
