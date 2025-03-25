class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false

      t.string  :title, null: false
      t.string  :slug, null: false
      t.string  :description
      t.text    :content
      t.string  :media

      t.timestamps
    end

    add_index :pages, :slug, unique: true
  end
end
