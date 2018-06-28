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

ActiveRecord::Schema.define(version: 2018_06_27_161720) do

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

  create_table "authors", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.string "preferred_first_name"
    t.string "preferred_last_name"
    t.string "preferred_middle_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "contributions", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "author_id"
    t.integer "publication_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_contributions_on_author_id"
    t.index ["publication_id", "author_id"], name: "index_contributions_on_publication_id_and_author_id"
    t.index ["publication_id"], name: "index_contributions_on_publication_id"
  end

  create_table "publication_identifiers", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.integer "publication_id"
    t.string "identifier_type"
    t.string "identifier_value"
    t.string "identifier_uri"
    t.string "certainty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier_type", "publication_id"], name: "pub_identifier_index_by_pub_and_type"
    t.index ["identifier_type"], name: "index_publication_identifiers_on_identifier_type"
    t.index ["publication_id", "identifier_type"], name: "pub_identifier_index_by_type_and_pub"
    t.index ["publication_id"], name: "index_publication_identifiers_on_publication_id"
  end

  create_table "publications", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.boolean "active"
    t.boolean "deleted"
    t.string "title"
    t.integer "year"
    t.integer "lock_version"
    t.text "xml"
    t.text "pub_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "wos_uid"
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

  create_table "web_of_science_source_records", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.boolean "active"
    t.string "database"
    t.text "source_data"
    t.string "source_fingerprint"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "doi"
    t.string "pmid"
    t.string "sourceurl"
    t.string "authoremails"
    t.integer "publication_id"
    t.string "contactnames"
    t.index ["doi"], name: "web_of_science_doi_index"
    t.index ["pmid"], name: "web_of_science_pmid_index"
    t.index ["uid"], name: "web_of_science_uid_index"
  end

end
