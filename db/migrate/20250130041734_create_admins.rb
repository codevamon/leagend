class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :club, null: false, foreign_key: true
      t.references :clan, null: false, foreign_key: true
      t.integer    :level, default: 0
      t.timestamps
    end
  end
end
