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

ActiveRecord::Schema.define(version: 2018_07_17_200122) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "author_publications", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "publication_id"
    t.string "email"
    t.string "name"
    t.string "primary_affiliation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_author_publications_on_publication_id"
  end

  create_table "cas_users", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "display_name"
    t.boolean "admin", default: false
    t.index ["email"], name: "index_cas_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_cas_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_cas_users_on_username", unique: true
  end

  create_table "cas_users_publications", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "cas_user_id", null: false
    t.bigint "publication_id", null: false
  end

  create_table "events", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "publication_id"
    t.string "name"
    t.string "status"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.bigint "cas_user_id"
    t.string "restartable_state"
    t.boolean "restartable", default: false
    t.index ["cas_user_id"], name: "index_events_on_cas_user_id"
    t.index ["publication_id"], name: "index_events_on_publication_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "publications", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.boolean "active"
    t.boolean "deleted"
    t.string "title"
    t.integer "year"
    t.integer "lock_version"
    t.text "xml"
    t.text "pub_hash"
    t.datetime "pub_at"
    t.string "pub_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "publications_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "publication_id", null: false
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.boolean "admin", default: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "web_of_science_source_records", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.boolean "active"
    t.string "database"
    t.text "source_data"
    t.string "source_fingerprint"
    t.string "source_url"
    t.string "authors"
    t.string "uid"
    t.string "doi"
    t.string "pmid"
    t.bigint "publication_id"
    t.string "hashed_uid"
    t.index ["publication_id"], name: "index_web_of_science_source_records_on_publication_id"
  end

  add_foreign_key "events", "cas_users"
  add_foreign_key "events", "publications"
  add_foreign_key "events", "users"
  add_foreign_key "web_of_science_source_records", "publications"
end
