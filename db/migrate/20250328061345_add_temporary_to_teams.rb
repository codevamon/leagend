class AddTemporaryToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :temporary, :boolean
    add_column :teams, :expires_at, :datetime
  end
end
