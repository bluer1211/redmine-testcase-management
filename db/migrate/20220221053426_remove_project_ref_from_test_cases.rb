class RemoveProjectRefFromTestCases < ActiveRecord::Migration[5.2]
  def change
    remove_reference :test_cases, :project, foreign_key: true
  end
end
