class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
      t.string :name

      # Relaciones opcionales explícitas
      t.string :club_id, limit: 36, null: true
      t.string :clan_id, limit: 36, null: true

      # Capitán del equipo
      t.string :captain_id, limit: 36, null: true

      # Relación polimórfica con Club o Clan
      t.string :joinable_type
      t.string :joinable_id, limit: 36

      # Estado del equipo (enum opcional)
      t.integer :status

      t.timestamps
    end

    # Claves foráneas explícitas
    add_foreign_key :teams, :users, column: :captain_id, primary_key: :id
    add_foreign_key :teams, :clubs, column: :club_id, primary_key: :id
    add_foreign_key :teams, :clans, column: :clan_id, primary_key: :id
  end
end
