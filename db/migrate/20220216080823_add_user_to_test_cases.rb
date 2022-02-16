class AddUserToTestCases < ActiveRecord::Migration[5.2]
  def change
    add_reference :test_cases, :user, foreign_key: true
  end
end
