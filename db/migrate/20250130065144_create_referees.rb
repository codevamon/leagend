class CreateReferees < ActiveRecord::Migration[8.0]
  def change
    create_table :referees, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, null: false, foreign_key: true
      t.decimal :fee, precision: 8, scale: 2, default: 0.0
      t.boolean :available

      t.timestamps
    end
  end
end
