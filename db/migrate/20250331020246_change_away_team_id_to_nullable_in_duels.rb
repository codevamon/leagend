class ChangeAwayTeamIdToNullableInDuels < ActiveRecord::Migration[8.0]
  def change
    change_column_null :duels, :away_team_id, true
  end
end
