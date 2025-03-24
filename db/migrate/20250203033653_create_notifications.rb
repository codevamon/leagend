class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.string :recipient_type, null: false
      t.string :recipient_id, null: false

      t.string :sender_type, null: false
      t.string :sender_id, null: false

      t.string :message, null: false
      t.integer :category, default: 0
      t.integer :status, default: 0

      t.string :notifiable_type
      t.string :notifiable_id

      t.timestamps
    end

    add_index :notifications, [:recipient_type, :recipient_id]
    add_index :notifications, [:sender_type, :sender_id]
    add_index :notifications, [:notifiable_type, :notifiable_id]
  end
end
