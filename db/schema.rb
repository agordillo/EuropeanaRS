# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151027093519) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apps", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "app_key"
    t.string   "app_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "europeana_user_auths", force: :cascade do |t|
    t.text     "public_key"
    t.text     "private_key"
    t.text     "session_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lo_profiles", force: :cascade do |t|
    t.integer  "lo_id"
    t.string   "repository"
    t.text     "id_repository"
    t.text     "title"
    t.text     "description"
    t.string   "language"
    t.integer  "year"
    t.string   "resource_type"
    t.integer  "quality",       default: 0
    t.integer  "popularity",    default: 0
    t.text     "url"
    t.text     "thumbnail_url"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "lo_profiles_user_profiles", id: false, force: :cascade do |t|
    t.integer "user_profile_id"
    t.integer "lo_profile_id"
  end

  create_table "lo_profiles_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "lo_profile_id"
  end

  create_table "los", force: :cascade do |t|
    t.text     "europeana_metadata"
    t.text     "id_europeana"
    t.text     "url"
    t.text     "title"
    t.text     "description"
    t.string   "language"
    t.text     "thumbnail_url"
    t.integer  "year"
    t.integer  "metadata_quality"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.text     "full_url"
    t.string   "europeana_collection_name"
    t.string   "country"
    t.string   "resource_type"
    t.string   "europeana_skos_concept"
    t.integer  "visit_count",                               default: 0
    t.integer  "like_count",                                default: 0
    t.integer  "popularity",                                default: 0
    t.integer  "resource_type_crc32",             limit: 8
    t.integer  "language_crc32",                  limit: 8
    t.integer  "europeana_collection_name_crc32", limit: 8
    t.integer  "country_crc32",                   limit: 8
    t.integer  "europeana_skos_concept_crc32",    limit: 8
    t.integer  "id_europeana_crc32",              limit: 8
  end

  create_table "los_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "lo_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.text     "session_id"
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "user_profiles", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "app_id"
    t.integer  "id_app"
    t.string   "language"
    t.string   "settings"
    t.text     "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.text     "settings"
    t.string   "language"
    t.string   "ui_language"
    t.string   "provider"
    t.string   "uid"
    t.boolean  "ug_password_flag",       default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["provider"], name: "index_users_on_provider", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", using: :btree

  create_table "words", force: :cascade do |t|
    t.string  "value"
    t.integer "occurrences", default: 0
  end

end
