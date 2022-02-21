class AddTestProjectRefToTestPlans < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_plans, :test_project, foreign_key: true
  end
end
