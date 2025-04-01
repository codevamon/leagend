# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_01_044111) do
# Could not dump table "active_storage_attachments" because of following StandardError
#   Unknown type 'uuid' for column 'record_id'


  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

# Could not dump table "admins" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "arenas", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "owner_id", limit: 36, null: false
    t.string "name"
    t.string "slug"
    t.string "address"
    t.string "city"
    t.string "country"
    t.string "neighborhood"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "prestige", precision: 10, scale: 2, default: "0.0"
    t.boolean "private", default: false
    t.boolean "rentable", default: false
    t.decimal "price_per_hour", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_arenas_on_slug", unique: true
  end

# Could not dump table "callups" because of following StandardError
#   Unknown type 'uuid' for column 'duel_id'


  create_table "challenges", force: :cascade do |t|
    t.string "challenger_duel_id", null: false
    t.string "challengee_duel_id", null: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challengee_duel_id"], name: "index_challenges_on_challengee_duel_id"
    t.index ["challenger_duel_id"], name: "index_challenges_on_challenger_duel_id"
  end

# Could not dump table "clans" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "clubs" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "duel_goals" because of following StandardError
#   Unknown type 'uuid' for column 'duel_id'


# Could not dump table "duels" because of following StandardError
#   Unknown type '' for column 'referee_id'


  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

# Could not dump table "lineups" because of following StandardError
#   Unknown type 'uuid' for column 'duel_id'


# Could not dump table "memberships" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "notifications", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "recipient_type", null: false
    t.string "recipient_id", limit: 36, null: false
    t.string "sender_type", null: false
    t.string "sender_id", limit: 36, null: false
    t.string "message", null: false
    t.integer "category", default: 0
    t.integer "status", default: 0
    t.string "notifiable_type"
    t.string "notifiable_id", limit: 36
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
    t.index ["sender_type", "sender_id"], name: "index_notifications_on_sender_type_and_sender_id"
  end

# Could not dump table "owners" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "pages", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.string "description"
    t.text "content"
    t.string "media"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

# Could not dump table "referees" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "reservations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "reservable_type", null: false
    t.string "reservable_id", limit: 36, null: false
    t.string "payer_id", limit: 36, null: false
    t.string "receiver_id", limit: 36, null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "price_per_hour", precision: 8, scale: 2
    t.decimal "total_price", precision: 10, scale: 2
    t.boolean "confirmed", default: false
    t.string "purpose"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservable_type", "reservable_id"], name: "index_reservations_on_reservable_type_and_reservable_id"
  end

# Could not dump table "results" because of following StandardError
#   Unknown type '' for column 'duel_id'


  create_table "teams", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "name"
    t.string "club_id", limit: 36
    t.string "clan_id", limit: 36
    t.string "captain_id", limit: 36
    t.string "joinable_type"
    t.string "joinable_id", limit: 36
    t.integer "status"
    t.boolean "temporary"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "slug", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider"
    t.string "uid"
    t.string "firstname"
    t.string "lastname"
    t.string "phone_number", null: false
    t.string "country_code", limit: 5
    t.string "country"
    t.string "city"
    t.string "neighborhood"
    t.string "avatar"
    t.string "cover"
    t.text "bio"
    t.datetime "birthday"
    t.boolean "owner", default: false
    t.boolean "partner", default: false
    t.boolean "active", default: false
    t.boolean "live", default: false
    t.integer "status", default: 0, null: false
    t.integer "prestige", default: 0, null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "height_cm", precision: 8, scale: 2
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.datetime "locked_at"
    t.string "position"
    t.integer "dorsal", default: 0, null: false
    t.integer "fav", default: 0, null: false
    t.decimal "height", precision: 8, scale: 2
    t.decimal "skills", precision: 8, scale: 2
    t.decimal "rate", precision: 8, scale: 2
    t.decimal "shot", precision: 8, scale: 2
    t.decimal "pass", precision: 8, scale: 2
    t.decimal "cross", precision: 8, scale: 2
    t.decimal "dribbling", precision: 8, scale: 2
    t.decimal "defense", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admins", "clans"
  add_foreign_key "admins", "clubs"
  add_foreign_key "admins", "users"
  add_foreign_key "arenas", "owners"
  add_foreign_key "callups", "duels"
  add_foreign_key "callups", "users"
  add_foreign_key "clans", "users"
  add_foreign_key "clubs", "users"
  add_foreign_key "duel_goals", "duels"
  add_foreign_key "duel_goals", "teams"
  add_foreign_key "duel_goals", "users"
  add_foreign_key "duels", "arenas"
  add_foreign_key "duels", "users", column: "best_player_id"
  add_foreign_key "duels", "users", column: "referee_id"
  add_foreign_key "lineups", "duels"
  add_foreign_key "lineups", "users"
  add_foreign_key "memberships", "users"
  add_foreign_key "owners", "users"
  add_foreign_key "referees", "users"
  add_foreign_key "reservations", "users", column: "payer_id"
  add_foreign_key "reservations", "users", column: "receiver_id"
  add_foreign_key "results", "duels"
  add_foreign_key "results", "users", column: "best_player_id"
  add_foreign_key "results", "users", column: "referee_id"
  add_foreign_key "teams", "clans"
  add_foreign_key "teams", "clubs"
  add_foreign_key "teams", "users", column: "captain_id"
end
