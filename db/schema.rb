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

ActiveRecord::Schema.define(version: 20170602191919) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clinics", force: :cascade do |t|
    t.integer  "resmap_id"
    t.string   "name"
    t.string   "short_name"
    t.string   "address"
    t.string   "schedule"
    t.string   "walk_in_schedule"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "selected_times",   default: 0,     null: false
    t.boolean  "free_clinic",      default: false
    t.boolean  "women_care",       default: false
    t.float    "latitude"
    t.float    "longitude"
    t.string   "borough"
    t.integer  "rated_times",      default: 0
    t.float    "avg_rating"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_clinics_on_deleted_at", using: :btree
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "phone"
    t.string   "survey_status"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "clinic1_id"
    t.integer  "clinic2_id"
    t.integer  "clinic3_id"
    t.string   "tracking_status"
    t.datetime "call_started_at"
    t.string   "call_sid"
    t.boolean  "pregnant"
    t.boolean  "urgent"
    t.boolean  "known_condition"
    t.string   "borough"
    t.string   "language"
    t.boolean  "survey_was_seen"
    t.integer  "survey_chosen_clinic_id"
    t.integer  "survey_clinic_rating"
    t.boolean  "survey_can_be_called"
    t.string   "survey_reason_not_seen"
    t.datetime "survey_scheduled_at"
    t.datetime "survey_updated_at"
    t.integer  "age"
    t.index ["clinic1_id"], name: "index_contacts_on_clinic1_id", using: :btree
    t.index ["clinic2_id"], name: "index_contacts_on_clinic2_id", using: :btree
    t.index ["clinic3_id"], name: "index_contacts_on_clinic3_id", using: :btree
  end

  add_foreign_key "contacts", "clinics", column: "clinic1_id"
  add_foreign_key "contacts", "clinics", column: "clinic2_id"
  add_foreign_key "contacts", "clinics", column: "clinic3_id"
end
