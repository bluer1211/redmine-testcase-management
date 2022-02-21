class CreateTestProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :test_projects do |t|
      t.belongs_to :project, foreign_key: true
    end
    add_index :test_projects, :project_id
  end
end
