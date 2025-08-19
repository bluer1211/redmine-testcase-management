class CreateTestCases < ActiveRecord::Migration[7.2]
  def change
    create_table :test_cases do |t|
      t.string :name
      t.text :scenario
      t.text :expected
      t.text :environment
      t.datetime :scheduled_date
    end
  end
end
