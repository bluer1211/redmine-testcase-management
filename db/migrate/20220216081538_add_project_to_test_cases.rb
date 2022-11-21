class AddProjectToTestCases < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_cases, :project, foreign_key: true, type: :integer
  end
end
