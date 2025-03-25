class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :club, null: true, foreign_key: true, type: :uuid
      t.references :clan, null: true, foreign_key: true, type: :uuid
      t.integer    :level, default: 0
      t.timestamps
    end
  end
end
