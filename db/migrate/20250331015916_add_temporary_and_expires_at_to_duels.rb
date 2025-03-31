class AddTemporaryAndExpiresAtToDuels < ActiveRecord::Migration[8.0]
  def change
    add_column :duels, :temporary, :boolean
    add_column :duels, :expires_at, :datetime
  end
end
