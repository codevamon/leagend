class CreateTeamMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :team_memberships, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :club, null: true, foreign_key: true, type: :uuid
      t.references :clan, null: true, foreign_key: true, type: :uuid
      t.string :captain_id, limit: 36, null: true
      t.integer :status

      t.timestamps
    end
    add_foreign_key :team_memberships, :users, column: :captain_id, primary_key: :id
  end
end
