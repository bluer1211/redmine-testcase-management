class CreateTestProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :test_projects do |t|
      t.belongs_to :project, foreign_key: true, type: :integer
    end
  end
end
