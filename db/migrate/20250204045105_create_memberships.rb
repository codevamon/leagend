class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :joinable_type, null: false  # Guarda el tipo de modelo (Club o Clan)
      t.string :joinable_id, null: false, type: :uuid  # Para SQLite, almacenamos UUID como string
      t.integer :status
      t.integer :role

      t.timestamps
    end

    add_index :memberships, [:joinable_type, :joinable_id]
  end
end
