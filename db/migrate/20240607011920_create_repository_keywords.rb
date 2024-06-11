class CreateRepositoryKeywords < ActiveRecord::Migration[7.0]
  def change
    create_table :repository_keywords do |t|
      t.string :keyword, null: false
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end

    add_index :repository_keywords, :keyword
  end
end