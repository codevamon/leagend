class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :name

      # Usamos string (UUID) en vez de t.references con type: :uuid por compatibilidad con SQLite
      t.string :club_id, limit: 36, null: true
      t.string :clan_id, limit: 36, null: true

      t.string :captain_id, limit: 36, null: true
      t.integer :status

      t.timestamps
    end

    add_foreign_key :teams, :users, column: :captain_id, primary_key: :id
    add_foreign_key :teams, :clubs, column: :club_id, primary_key: :id
    add_foreign_key :teams, :clans, column: :clan_id, primary_key: :id
  end
end
