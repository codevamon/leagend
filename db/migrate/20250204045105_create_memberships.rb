class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :joinable, polymorphic: true, null: false # Para Club o Clan
      t.integer :status
      t.integer :role

      t.timestamps
    end
  end
end
