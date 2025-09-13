class CreateAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :availabilities, id: :uuid do |t|
      t.references :availablable, polymorphic: true, type: :uuid, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :reason
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end
