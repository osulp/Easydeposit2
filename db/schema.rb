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

ActiveRecord::Schema.define(version: 2018_05_15_214438) do

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
  end

  create_table "web_of_science_source_records", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.boolean "active"
    t.string "database"
    t.text "source_data"
    t.string "source_fingerprint"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "web_of_science_uid_index"
  end

end
