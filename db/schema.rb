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

ActiveRecord::Schema.define(version: 20151002135218) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.text     "full_url"
    t.string   "europeana_collection_name"
    t.string   "country"
    t.string   "resource_type"
    t.string   "europeana_skos_concept"
    t.integer  "resource_type_crc32",             limit: 8
    t.integer  "language_crc32",                  limit: 8
    t.integer  "europeana_collection_name_crc32", limit: 8
    t.integer  "country_crc32",                   limit: 8
    t.integer  "europeana_skos_concept_crc32",    limit: 8
  end

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

end
