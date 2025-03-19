class CreateTeamMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :team_memberships do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :team, null: false, foreign_key: true
      t.boolean    :leader

      t.timestamps
    end
  end
end
