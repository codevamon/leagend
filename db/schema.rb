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

ActiveRecord::Schema[8.0].define(version: 2025_08_10_050001) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.string "record_id", limit: 36, null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    t.index ["record_type", "record_id"], name: "index_active_storage_attachments_on_record"
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

  create_table "admins", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.string "club_id", limit: 36
    t.string "clan_id", limit: 36
    t.integer "level", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id"], name: "index_admins_on_clan_id"
    t.index ["club_id"], name: "index_admins_on_club_id"
    t.index ["user_id"], name: "index_admins_on_user_id"
  end

  create_table "arena_business_hours", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "arena_id", limit: 36, null: false
    t.integer "weekday", null: false
    t.time "opens_at"
    t.time "closes_at"
    t.boolean "closed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["arena_id", "weekday"], name: "index_arena_business_hours_on_arena_id_and_weekday", unique: true
  end

  create_table "arena_closures", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "arena_id", limit: 36, null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["arena_id"], name: "index_arena_closures_on_arena_id"
    t.index ["ends_at"], name: "index_arena_closures_on_ends_at"
    t.index ["starts_at"], name: "index_arena_closures_on_starts_at"
  end

  create_table "arena_verifications", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "arena_id", limit: 36, null: false
    t.string "submitted_by_id", limit: 36, null: false
    t.string "status", default: "draft", null: false
    t.text "rejection_reason"
    t.string "payout_method"
    t.json "payout_payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["arena_id"], name: "index_arena_verifications_on_arena_id"
    t.index ["status"], name: "index_arena_verifications_on_status"
  end

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
    t.string "status", default: "unverified", null: false
    t.json "amenities", default: {}
    t.text "cancellation_policy"
    t.integer "deposit_cents", default: 0
    t.string "currency", default: "COP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["slug"], name: "index_arenas_on_slug", unique: true
    t.index ["status"], name: "index_arenas_on_status"
  end

  create_table "callups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "duel_id", limit: 36
    t.string "user_id", limit: 36, null: false
    t.string "teamable_type", null: false
    t.string "teamable_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duel_id", "user_id", "teamable_id", "teamable_type"], name: "idx_on_duel_id_user_id_teamable_id_teamable_type_1d1e3ae175", unique: true
    t.index ["duel_id"], name: "index_callups_on_duel_id"
    t.index ["teamable_type", "teamable_id"], name: "index_callups_on_teamable"
    t.index ["user_id"], name: "index_callups_on_user_id"
  end

  create_table "challenges", force: :cascade do |t|
    t.string "challenger_duel_id", null: false
    t.string "challengee_duel_id", null: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challengee_duel_id"], name: "index_challenges_on_challengee_duel_id"
    t.index ["challenger_duel_id"], name: "index_challenges_on_challenger_duel_id"
  end

  create_table "clans", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.string "slug", default: "", null: false
    t.string "name"
    t.string "country"
    t.string "city"
    t.string "neighborhood"
    t.string "address"
    t.text "description"
    t.integer "status"
    t.integer "price"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.boolean "active", default: false
    t.string "main_color", default: "#000000"
    t.string "other_color", default: "#FFFFFF"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_clans_on_slug", unique: true
    t.index ["user_id"], name: "index_clans_on_user_id"
  end

  create_table "clubs", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.string "slug", default: "", null: false
    t.string "name"
    t.string "country"
    t.string "city"
    t.string "neighborhood"
    t.string "address"
    t.integer "sport"
    t.integer "status"
    t.integer "price"
    t.text "description"
    t.decimal "prestige", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.boolean "private", default: false
    t.boolean "uniform", default: false
    t.boolean "training", default: false
    t.boolean "active", default: false
    t.boolean "lockers", default: false
    t.boolean "snacks", default: false
    t.boolean "payroll", default: false
    t.boolean "bathrooms", default: false
    t.boolean "staff", default: false
    t.boolean "assistance", default: false
    t.boolean "roof", default: false
    t.boolean "parking", default: false
    t.boolean "wifi", default: false
    t.boolean "gym", default: false
    t.boolean "showers", default: false
    t.boolean "amenities", default: false
    t.boolean "payment", default: false
    t.boolean "transport", default: false
    t.boolean "lunch", default: false
    t.boolean "videogames", default: false
    t.boolean "air", default: false
    t.boolean "pools", default: false
    t.boolean "front", default: false
    t.string "main_color", default: "#000000"
    t.string "other_color", default: "#FFFFFF"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_clubs_on_slug", unique: true
    t.index ["user_id"], name: "index_clubs_on_user_id"
  end

  create_table "duel_goals", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "duel_id", limit: 36, null: false
    t.string "user_id", limit: 36, null: false
    t.string "team_id", limit: 36, null: false
    t.integer "minute"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duel_id"], name: "index_duel_goals_on_duel_id"
    t.index ["team_id"], name: "index_duel_goals_on_team_id"
    t.index ["user_id"], name: "index_duel_goals_on_user_id"
  end

  create_table "duels", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "home_team_id", limit: 36
    t.string "away_team_id", limit: 36
    t.string "club_id"
    t.string "clan_id"
    t.string "referee_id", limit: 36
    t.string "best_player_id", limit: 36
    t.string "arena_id", limit: 36
    t.datetime "starts_at"
    t.datetime "ends_at"
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
    t.integer "duration", default: 0
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
    t.boolean "allow_freeplayers", default: false
    t.boolean "allow_freereferees", default: false
    t.boolean "allow_freearenas", default: false
    t.boolean "club_association_pending", default: false
    t.integer "home_goals", default: 0
    t.integer "away_goals", default: 0
    t.boolean "hunted", default: false
    t.boolean "temporary", default: true
    t.datetime "expires_at"
    t.boolean "responsibility", default: false
    t.string "why"
    t.string "mode"
    t.integer "challenge", default: 0
    t.integer "challenge_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["arena_id"], name: "index_duels_on_arena_id"
    t.index ["clan_id"], name: "index_duels_on_clan_id"
    t.index ["club_id"], name: "index_duels_on_club_id"
    t.index ["duel_type"], name: "index_duels_on_duel_type"
    t.index ["ends_at"], name: "index_duels_on_ends_at"
    t.index ["referee_id"], name: "index_duels_on_referee_id"
    t.index ["starts_at"], name: "index_duels_on_starts_at"
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

  create_table "lineups", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "duel_id", limit: 36, null: false
    t.string "teamable_type", null: false
    t.string "teamable_id", null: false
    t.string "user_id", limit: 36, null: false
    t.string "position"
    t.integer "formation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["duel_id"], name: "index_lineups_on_duel_id"
    t.index ["teamable_type", "teamable_id"], name: "index_lineups_on_teamable"
    t.index ["user_id"], name: "index_lineups_on_user_id"
  end

  create_table "memberships", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.string "joinable_type", null: false
    t.string "joinable_id", limit: 36, null: false
    t.integer "status"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["joinable_type", "joinable_id"], name: "index_memberships_on_joinable_type_and_joinable_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

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

  create_table "owners", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.integer "level", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_owners_on_user_id"
  end

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

  create_table "referees", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "user_id", limit: 36, null: false
    t.decimal "fee", precision: 8, scale: 2, default: "0.0"
    t.boolean "available"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_referees_on_user_id"
  end

  create_table "reservations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "reservable_type", null: false
    t.string "reservable_id", limit: 36, null: false
    t.string "payer_id", limit: 36, null: false
    t.string "receiver_id", limit: 36, null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "status", default: "held", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "currency", default: "COP", null: false
    t.string "payment_provider"
    t.string "payment_ref"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ends_at"], name: "index_reservations_on_ends_at"
    t.index ["reservable_type", "reservable_id", "starts_at", "ends_at"], name: "idx_reservable_time_window"
    t.index ["reservable_type", "reservable_id"], name: "index_reservations_on_reservable_type_and_reservable_id"
    t.index ["starts_at"], name: "index_reservations_on_starts_at"
    t.index ["status"], name: "index_reservations_on_status"
    t.check_constraint "ends_at > starts_at", name: "chk_reservations_time_window"
  end

  create_table "results", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "duel_id", limit: 36, null: false
    t.string "home_teamable_type", null: false
    t.string "home_teamable_id", null: false
    t.string "away_teamable_type", null: false
    t.string "away_teamable_id", null: false
    t.string "referee_id", limit: 36
    t.string "best_player_id", limit: 36
    t.integer "outcome", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["away_teamable_type", "away_teamable_id"], name: "index_results_on_away_teamable"
    t.index ["duel_id", "away_teamable_id", "away_teamable_type"], name: "index_results_on_duel_and_away_teamable"
    t.index ["duel_id", "home_teamable_id", "home_teamable_type"], name: "index_results_on_duel_and_home_teamable"
    t.index ["duel_id"], name: "index_results_on_duel_id"
    t.index ["home_teamable_type", "home_teamable_id"], name: "index_results_on_home_teamable"
    t.index ["referee_id"], name: "index_results_on_referee_id"
  end

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
    t.string "current_country"
    t.string "current_city"
    t.string "current_neighborhood"
    t.string "current_address"
    t.string "current_zip"
    t.string "current_latitude"
    t.string "current_longitude"
    t.string "current_timezone"
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
  add_foreign_key "arena_business_hours", "arenas"
  add_foreign_key "arena_closures", "arenas"
  add_foreign_key "arena_verifications", "arenas"
  add_foreign_key "arena_verifications", "users", column: "submitted_by_id"
  add_foreign_key "arenas", "owners"
  add_foreign_key "callups", "duels"
  add_foreign_key "callups", "users"
  add_foreign_key "clans", "users"
  add_foreign_key "clubs", "users"
  add_foreign_key "duel_goals", "duels"
  add_foreign_key "duel_goals", "teams"
  add_foreign_key "duel_goals", "users"
  add_foreign_key "duels", "arenas"
  add_foreign_key "duels", "clans"
  add_foreign_key "duels", "clubs"
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
