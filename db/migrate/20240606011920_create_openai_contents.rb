class CreateOpenaiContents < ActiveRecord::Migration[7.0]
  def change
    create_table :openai_contents do |t|
      t.integer :project_id
      t.text :about
      t.text :example_code
      t.text :use_cases
      t.text :tags
      t.text :faqs

      t.timestamps
    end
    add_index :openai_contents, :project_id
  end
end