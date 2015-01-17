class CreateTools < ActiveRecord::Migration
  def change
    create_table :tools do |t|
      t.string :title
      t.string :description
      t.string :body

      t.timestamps null: false
    end
  end
end
