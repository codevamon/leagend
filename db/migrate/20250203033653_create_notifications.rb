class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, polymorphic: true, null: false
      t.references :sender, polymorphic: true, null: false
      t.string :message, null: false
      t.integer :category, default: 0
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
