class AddProjectToTestCases < ActiveRecord::Migration[7.2]
  def change
    add_reference :test_cases, :project, foreign_key: true, type: :integer
  end
end
