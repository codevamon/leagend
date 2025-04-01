class CreateChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :challenges do |t|
      # Usamos string para almacenar el UUID de Duels.
      t.string :challenger_duel_id, null: false
      t.string :challengee_duel_id, null: false

      t.string :status, default: 'pending'  # pending, accepted, rejected

      t.timestamps
    end

    # Índices opcionales: facilitan las búsquedas por ID
    add_index :challenges, :challenger_duel_id
    add_index :challenges, :challengee_duel_id
  end
end
