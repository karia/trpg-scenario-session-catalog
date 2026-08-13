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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_160305) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "author_aliases", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["author_id"], name: "index_author_aliases_on_author_id"
  end

  create_table "authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "person_id", null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "scenario_id"], name: "index_favorites_on_person_id_and_scenario_id", unique: true
    t.index ["person_id"], name: "index_favorites_on_person_id"
    t.index ["scenario_id"], name: "index_favorites_on_scenario_id"
  end

  create_table "game_system_aliases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_system_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["game_system_id"], name: "index_game_system_aliases_on_game_system_id"
  end

  create_table "game_systems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "game_master_label"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_game_systems_on_name", unique: true
  end

  create_table "group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["person_id", "group_id"], name: "index_group_memberships_on_person_id_and_group_id", unique: true
    t.index ["person_id"], name: "index_group_memberships_on_person_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "participations", force: :cascade do |t|
    t.string "character_name"
    t.string "character_sheet_url"
    t.datetime "created_at", null: false
    t.bigint "person_id", null: false
    t.bigint "play_session_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_participations_on_person_id"
    t.index ["play_session_id", "person_id"], name: "index_participations_on_play_session_id_and_person_id", unique: true
    t.index ["play_session_id"], name: "index_participations_on_play_session_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.datetime "updated_at", null: false
    t.string "x_account"
  end

  create_table "person_aliases", force: :cascade do |t|
    t.string "context"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "person_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["person_id"], name: "index_person_aliases_on_person_id"
  end

  create_table "person_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "name", null: false
    t.bigint "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "name"], name: "index_person_roles_on_person_id_and_name", unique: true
    t.index ["person_id"], name: "index_person_roles_on_person_id"
  end

  create_table "play_sessions", force: :cascade do |t|
    t.string "cocofolia_url"
    t.datetime "created_at", null: false
    t.text "note"
    t.date "played_on"
    t.string "recording_url"
    t.bigint "scenario_id", null: false
    t.time "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["played_on"], name: "index_play_sessions_on_played_on"
    t.index ["scenario_id"], name: "index_play_sessions_on_scenario_id"
  end

  create_table "purchase_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["scenario_id"], name: "index_purchase_links_on_scenario_id"
  end

  create_table "recording_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "session_schedule_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["session_schedule_id"], name: "index_recording_links_on_session_schedule_id"
  end

  create_table "scenario_authors", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_scenario_authors_on_author_id"
    t.index ["scenario_id", "author_id"], name: "index_scenario_authors_on_scenario_id_and_author_id", unique: true
    t.index ["scenario_id"], name: "index_scenario_authors_on_scenario_id"
  end

  create_table "scenario_game_systems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_system_id", null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_system_id"], name: "index_scenario_game_systems_on_game_system_id"
    t.index ["scenario_id", "game_system_id"], name: "index_scenario_game_systems_on_scenario_id_and_game_system_id", unique: true
    t.index ["scenario_id"], name: "index_scenario_game_systems_on_scenario_id"
  end

  create_table "scenarios", force: :cascade do |t|
    t.string "character_restriction"
    t.integer "character_sheet_deadline"
    t.string "character_sheet_deadline_note"
    t.datetime "created_at", null: false
    t.decimal "duration_max_hours", precision: 4, scale: 1
    t.decimal "duration_min_hours", precision: 4, scale: 1
    t.boolean "gm_experienced", default: true, null: false
    t.integer "player_count_max"
    t.integer "player_count_min", null: false
    t.integer "position"
    t.text "preparation_note"
    t.integer "recommendation"
    t.text "recommendation_note"
    t.text "synopsis"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_scenarios_on_position"
    t.index ["title"], name: "index_scenarios_on_title"
  end

  create_table "session_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "play_session_id", null: false
    t.integer "position", default: 0, null: false
    t.date "scheduled_on"
    t.time "started_at"
    t.datetime "updated_at", null: false
    t.index ["play_session_id", "scheduled_on", "started_at"], name: "idx_on_play_session_id_scheduled_on_started_at_3d7aa28832"
    t.index ["play_session_id"], name: "index_session_schedules_on_play_session_id"
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "google_analytics_measurement_id", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spoiler_reveals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "person_id", null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id", "scenario_id"], name: "index_spoiler_reveals_on_person_id_and_scenario_id", unique: true
    t.index ["person_id"], name: "index_spoiler_reveals_on_person_id"
    t.index ["scenario_id"], name: "index_spoiler_reveals_on_scenario_id"
  end

  create_table "stream_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.integer "position", default: 0, null: false
    t.bigint "scenario_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["scenario_id"], name: "index_stream_links_on_scenario_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "google_uid", null: false
    t.bigint "person_id"
    t.datetime "updated_at", null: false
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["person_id"], name: "index_users_on_person_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "author_aliases", "authors"
  add_foreign_key "favorites", "people"
  add_foreign_key "favorites", "scenarios"
  add_foreign_key "game_system_aliases", "game_systems"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "people"
  add_foreign_key "participations", "people"
  add_foreign_key "participations", "play_sessions"
  add_foreign_key "person_aliases", "people"
  add_foreign_key "person_roles", "people"
  add_foreign_key "play_sessions", "scenarios"
  add_foreign_key "purchase_links", "scenarios"
  add_foreign_key "recording_links", "session_schedules"
  add_foreign_key "scenario_authors", "authors"
  add_foreign_key "scenario_authors", "scenarios"
  add_foreign_key "scenario_game_systems", "game_systems"
  add_foreign_key "scenario_game_systems", "scenarios"
  add_foreign_key "session_schedules", "play_sessions"
  add_foreign_key "spoiler_reveals", "people"
  add_foreign_key "spoiler_reveals", "scenarios"
  add_foreign_key "stream_links", "scenarios"
  add_foreign_key "users", "people"
end
