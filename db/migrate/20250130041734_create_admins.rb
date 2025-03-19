class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :club, null: true, foreign_key: true, type: :uuid
      t.references :clan, null: true, foreign_key: true, type: :uuid
      t.integer    :level, default: 0
      t.timestamps
    end
  end
end
