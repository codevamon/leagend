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

ActiveRecord::Schema[8.0].define(version: 2025_02_04_050510) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

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


# Could not dump table "callups" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "clans" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "clubs" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "duel_goals" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "duels", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.integer "home_team_id", null: false
    t.integer "away_team_id", null: false
    t.integer "referee_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "address"
    t.string "neighborhood"
    t.string "city"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "price", precision: 8, scale: 2, default: "0.0"
    t.decimal "budget", precision: 8, scale: 2, default: "0.0"
    t.decimal "budget_place", precision: 8, scale: 2, default: "0.0"
    t.decimal "budget_equipment", precision: 8, scale: 2, default: "0.0"
    t.decimal "referee_price", precision: 8, scale: 2, default: "0.0"
    t.integer "status", default: 0
    t.integer "duel_type", default: 0
    t.decimal "duration", precision: 8, scale: 2
    t.boolean "timing", default: false
    t.boolean "referee_required", default: false
    t.boolean "live", default: false
    t.boolean "private", default: false
    t.boolean "streaming", default: false
    t.boolean "audience", default: false
    t.boolean "parking", default: false
    t.boolean "wifi", default: false
    t.boolean "lockers", default: false
    t.boolean "snacks", default: false
    t.integer "home_goals", default: 0
    t.integer "away_goals", default: 0
    t.boolean "hunted", default: false
    t.boolean "responsibility", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_duels_on_away_team_id"
    t.index ["duel_type"], name: "index_duels_on_duel_type"
    t.index ["end_date"], name: "index_duels_on_end_date"
    t.index ["home_team_id"], name: "index_duels_on_home_team_id"
    t.index ["referee_id"], name: "index_duels_on_referee_id"
    t.index ["start_date"], name: "index_duels_on_start_date"
    t.index ["status"], name: "index_duels_on_status"
  end

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
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "memberships" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.string "recipient_id", null: false
    t.string "sender_type", null: false
    t.string "sender_id", null: false
    t.string "message", null: false
    t.integer "category", default: 0
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
    t.index ["sender_type", "sender_id"], name: "index_notifications_on_sender_type_and_sender_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

# Could not dump table "referees" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


  create_table "results", force: :cascade do |t|
    t.integer "duel_id", null: false
    t.integer "team_id", null: false
    t.string "outcome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duel_id"], name: "index_results_on_duel_id"
    t.index ["team_id"], name: "index_results_on_team_id"
  end

# Could not dump table "team_memberships" because of following StandardError
#   Unknown type 'uuid' for column 'user_id'


# Could not dump table "teams" because of following StandardError
#   Unknown type 'uuid' for column 'club_id'


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
  add_foreign_key "callups", "duels"
  add_foreign_key "callups", "teams"
  add_foreign_key "callups", "users"
  add_foreign_key "clans", "users"
  add_foreign_key "clubs", "users"
  add_foreign_key "duel_goals", "duels"
  add_foreign_key "duel_goals", "teams"
  add_foreign_key "duel_goals", "users"
  add_foreign_key "duels", "teams", column: "away_team_id"
  add_foreign_key "duels", "teams", column: "home_team_id"
  add_foreign_key "duels", "users", column: "referee_id"
  add_foreign_key "lineups", "duels"
  add_foreign_key "lineups", "teams"
  add_foreign_key "lineups", "users"
  add_foreign_key "memberships", "users"
  add_foreign_key "referees", "users"
  add_foreign_key "results", "duels"
  add_foreign_key "results", "teams"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "clans"
  add_foreign_key "teams", "clubs"
end
