class DropTeamMembershipsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :team_memberships
  end
end
