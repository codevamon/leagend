class MakeDuelHomeTeamOptional < ActiveRecord::Migration[8.0]
  def change
    # Hacer home_team_id opcional en la tabla duels
    change_column_null :duels, :home_team_id, true
  end
end 