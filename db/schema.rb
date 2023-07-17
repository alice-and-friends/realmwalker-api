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

ActiveRecord::Schema[7.0].define(version: 2023_07_16_164144) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "battlefields", force: :cascade do |t|
    t.bigint "real_world_location_id"
    t.integer "status", default: 1
    t.integer "level", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["real_world_location_id"], name: "index_battlefields_on_real_world_location_id"
  end

  create_table "dungeons", force: :cascade do |t|
    t.bigint "real_world_location_id"
    t.integer "status", default: 1
    t.integer "level", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["real_world_location_id"], name: "index_dungeons_on_real_world_location_id"
  end

  create_table "npcs", force: :cascade do |t|
    t.bigint "real_world_location_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["real_world_location_id"], name: "index_npcs_on_real_world_location_id"
  end

  create_table "real_world_locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.string "ext_id", null: false
    t.point "coordinates", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "realm_locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "auth0_user_id"
    t.json "auth0_user_data"
    t.hstore "preferences"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
