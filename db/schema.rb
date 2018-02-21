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

ActiveRecord::Schema.define(version: 20180221102354) do

    create_table "author_identities", force: :cascade do |t|
      t.integer  "author_id",     limit: 4               
      t.integer  "identity_type", limit: 1, default: 0
      t.string   "first_name",    limit: 255,             null: false
      t.string   "middle_name",   limit: 255
      t.string   "last_name",     limit: 255,             null: false
      t.string   "email",         limit: 255,             null: false
      t.string   "institution",   limit: 255
      t.date     "start_date"
      t.date     "end_date"
      t.datetime "created_at",                            null: false
      t.datetime "updated_at",                            null: false
    end
  
    add_index "author_identities", ["email"], name: "index_author_identities_on_email", using: :btree
  
    create_table "publications", force: :cascade do |t|
      t.boolean  "active"
      t.boolean  "deleted"
      t.text     "title",                   limit: 65535
      t.integer  "year",                    limit: 4
      t.text     "pub_description",         limit: 16777215
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "pages",                   limit: 255
      t.string   "publication_type",        limit: 255
      t.string   "wos_uid",                 limit: 255
    end
  
    add_index "publications", ["title"], name: "index_publications_on_title", length: {"title"=>255}, using: :btree
    add_index "publications", ["updated_at"], name: "index_publications_on_updated_at", using: :btree
    add_index "publications", ["wos_uid"], name: "index_publications_on_wos_uid", using: :btree
    add_index "publications", ["year"], name: "index_publications_on_year", using: :btree
  
  
    create_table "web_of_science_source_records", force: :cascade do |t|
      t.boolean  "active"
      t.string   "database",           limit: 255
      t.text     "source_data",        limit: 16777215
      t.string   "source_fingerprint", limit: 255
      t.string   "uid",                limit: 255
      t.datetime "created_at",                          null: false
      t.datetime "updated_at",                          null: false
      t.string   "doi",                limit: 255
    end
  
    add_index "web_of_science_source_records", ["doi"], name: "web_of_science_doi_index", using: :btree
    add_index "web_of_science_source_records", ["uid"], name: "web_of_science_uid_index", using: :btree
  
  end