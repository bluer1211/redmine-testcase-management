class AddTestProjectRefToTestCases < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_cases, :test_project, foreign_key: true
  end
end
