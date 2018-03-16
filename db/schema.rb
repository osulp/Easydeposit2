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

ActiveRecord::Schema.define(version: 20180315152354) do

  create_table "authors", force: :cascade do |t|
    t.integer  "author_id",   limit: 4
    t.string   "first_name",  limit: 255, null: false
    t.string   "middle_name", limit: 255
    t.string   "last_name",   limit: 255, null: false
    t.string   "email",       limit: 255, null: false
    t.string   "institution", limit: 255
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "authors", ["email"], name: "index_authors_on_email"

  create_table "contributions", force: :cascade do |t|
    t.integer  "author_id",      limit: 4
    t.integer  "publication_id", limit: 4
    t.string   "status",         limit: 255
    t.boolean  "featured"
    t.string   "visibility",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contributions", ["author_id"], name: "index_contributions_on_author_id"
  add_index "contributions", ["publication_id"], name: "index_contributions_on_publication_id"

  create_table "publication_identifiers", force: :cascade do |t|
    t.integer  "publication_id",   limit: 4
    t.string   "identifier_type",  limit: 255
    t.string   "identifier_value", limit: 255
    t.string   "identifier_uri",   limit: 255
    t.string   "certainty",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "publication_identifiers", ["identifier_type", "identifier_value"], name: "pub_identifier_index_by_type_and_value"
  add_index "publication_identifiers", ["identifier_type", "publication_id"], name: "pub_identifier_index_by_pub_and_type"
  add_index "publication_identifiers", ["identifier_type"], name: "index_publication_identifiers_on_identifier_type"
  add_index "publication_identifiers", ["publication_id", "identifier_type"], name: "pub_identifier_index_by_type_and_pub"
  add_index "publication_identifiers", ["publication_id"], name: "index_publication_identifiers_on_publication_id"

  create_table "publications", force: :cascade do |t|
    t.boolean  "active"
    t.boolean  "deleted"
    t.text     "title",            limit: 65535
    t.integer  "year",             limit: 4
    t.integer  "lock_version",     limit: 4
    t.text     "pub_hash",         limit: 16777215
    t.integer  "pmid",             limit: 4
    t.integer  "sciencewire_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "pages",            limit: 255
    t.string   "issn",             limit: 255
    t.string   "publication_type", limit: 255
    t.string   "wos_uid",          limit: 255
  end

  add_index "publications", ["issn"], name: "index_publications_on_issn"
  add_index "publications", ["pages"], name: "index_publications_on_pages"
  add_index "publications", ["pmid"], name: "index_publications_on_pmid"
  add_index "publications", ["sciencewire_id"], name: "index_publications_on_sciencewire_id"
  add_index "publications", ["title"], name: "index_publications_on_title"
  add_index "publications", ["updated_at"], name: "index_publications_on_updated_at"
  add_index "publications", ["wos_uid"], name: "index_publications_on_wos_uid", unique: true
  add_index "publications", ["year"], name: "index_publications_on_year"

  create_table "web_of_science_source_records", force: :cascade do |t|
    t.boolean  "active"
    t.string   "database",           limit: 255
    t.text     "source_data",        limit: 16777215
    t.string   "source_fingerprint", limit: 255
    t.string   "uid",                limit: 255
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "doi",                limit: 255
    t.integer  "pmid",               limit: 4
    t.integer  "publication_id",     limit: 4
  end

  add_index "web_of_science_source_records", ["doi"], name: "web_of_science_doi_index"
  add_index "web_of_science_source_records", ["pmid"], name: "web_of_science_pmid_index"
  add_index "web_of_science_source_records", ["publication_id"], name: "index_web_of_science_source_records_on_publication_id", unique: true
  add_index "web_of_science_source_records", ["source_fingerprint"], name: "index_web_of_science_source_records_on_source_fingerprint", unique: true
  add_index "web_of_science_source_records", ["uid"], name: "index_web_of_science_source_records_on_uid", unique: true

end
