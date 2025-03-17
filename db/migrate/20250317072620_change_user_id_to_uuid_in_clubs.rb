class ChangeUserIdToUuidInClubs < ActiveRecord::Migration[8.0]
  def change
    remove_column :clubs, :user_id, :integer
    add_reference :clubs, :user, null: false, foreign_key: true, type: :uuid
  end
end
