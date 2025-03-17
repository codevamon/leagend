class ChangeAdminReferencesToUuid < ActiveRecord::Migration[8.0]
  def change
    remove_column :admins, :user_id
    remove_column :admins, :club_id
    remove_column :admins, :clan_id

    add_column :admins, :user_id, :uuid, null: false
    add_column :admins, :club_id, :uuid, null: true
    add_column :admins, :clan_id, :uuid, null: true

    add_foreign_key :admins, :users, column: :user_id
    add_foreign_key :admins, :clubs, column: :club_id
    add_foreign_key :admins, :clans, column: :clan_id
  end
end
