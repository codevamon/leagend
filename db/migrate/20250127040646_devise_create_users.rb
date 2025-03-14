# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: false, force: true do |t|
      ## Database authenticatable
      t.string   :id,                 limit: 36, primary_key: true, null: false
      t.string   :slug,               null: false, default: ""
      t.string   :email,              null: false, default: ""
      t.string   :encrypted_password, null: false, default: ""
      t.string   :provider
      t.string   :uid
      t.string   :firstname
      t.string   :lastname
      t.string   :phone_number,       null: false
      t.string   :country_code,       limit: 5
      t.string   :country
      t.string   :city
      t.string   :neighborhood            
      t.string   :avatar
      t.string   :cover
      t.text     :bio
      t.datetime :birthday
      t.boolean  :owner,              default: false
      t.boolean  :partner,            default: false
      t.boolean  :active,             default: false
      t.boolean  :live,               default: false
      t.integer  :status,             default: 0, null: false
      t.integer  :prestige,           default: 0, null: false
      t.decimal  :latitude,           precision: 10, scale: 6
      t.decimal  :longitude,          precision: 10, scale: 6
      t.decimal  :height_cm,          precision: 8, scale: 2

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      
      ## Player data
      t.string   :position
      t.integer  :dorsal, default: 00, null: false
      t.integer  :fav, default: 0, null: false
      t.decimal  :height, precision: 8, scale: 2
      t.decimal  :skills, precision: 8, scale: 2
      t.decimal  :rate, precision: 8, scale: 2
      t.decimal  :shot, precision: 8, scale: 2
      t.decimal  :pass, precision: 8, scale: 2
      t.decimal  :cross, precision: 8, scale: 2
      t.decimal  :dribbling, precision: 8, scale: 2
      t.decimal  :defense, precision: 8, scale: 2

      t.timestamps null: false
    end

    add_index :users, :slug,                 unique: true
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :uid,                  unique: true
    add_index :users, :phone_number,         unique: true
    # add_index :users, :unlock_token,         unique: true
  end
end
