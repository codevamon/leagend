class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships, id: false, force: true do |t|
      t.string :id, limit: 36, primary_key: true, null: false
    
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :joinable_type, null: false
      t.string :joinable_id, null: false, limit: 36
    
      t.integer :status
      t.integer :role
    
      t.timestamps
    end
    
    add_index :memberships, [:joinable_type, :joinable_id]
    
  end
end
