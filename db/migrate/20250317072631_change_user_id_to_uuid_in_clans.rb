class ChangeUserIdToUuidInClans < ActiveRecord::Migration[8.0]
  def change
    remove_column :clans, :user_id, :integer
    add_reference :clans, :user, null: false, foreign_key: true, type: :uuid
  end
end
