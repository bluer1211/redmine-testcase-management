class AddIssueStatusToTestPlans < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_plans, :issue_status, foreign_key: { to_table: :issue_statuses }, type: :integer
  end
end
