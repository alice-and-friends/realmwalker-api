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

ActiveRecord::Schema[7.0].define(version: 2023_07_26_221221) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "battlefields", force: :cascade do |t|
    t.bigint "real_world_location_id"
    t.bigint "dungeon_id"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dungeon_id"], name: "index_battlefields_on_dungeon_id"
    t.index ["real_world_location_id"], name: "index_battlefields_on_real_world_location_id"
  end

  create_table "dungeons", force: :cascade do |t|
    t.bigint "real_world_location_id"
    t.integer "status", default: 1
    t.integer "level", null: false
    t.bigint "monster_id"
    t.datetime "defeated_at"
    t.bigint "defeated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["defeated_by_id"], name: "index_dungeons_on_defeated_by_id"
    t.index ["monster_id"], name: "index_dungeons_on_monster_id"
    t.index ["real_world_location_id"], name: "index_dungeons_on_real_world_location_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "item_id"
    t.boolean "is_equipped", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_inventory_items_on_item_id"
    t.index ["user_id"], name: "index_inventory_items_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.string "rarity", null: false
    t.string "dropped_by_classification", default: [], array: true
    t.integer "dropped_by_level"
    t.boolean "two_handed"
    t.integer "attack_bonus", limit: 2, default: 0
    t.integer "defense_bonus", limit: 2, default: 0
    t.string "classification_bonus"
    t.integer "classification_attack_bonus", limit: 2, default: 0
    t.integer "classification_defense_bonus", limit: 2, default: 0
    t.float "xp_bonus", default: 0.0
    t.float "loot_bonus", default: 0.0
    t.integer "npc_buy"
    t.integer "npc_sell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "monsters", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.integer "level", null: false
    t.string "classification", null: false
    t.text "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.integer "xp", default: 0
    t.integer "level", default: 1
    t.integer "gold", default: 10
    t.text "achievements", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "dungeons", "users", column: "defeated_by_id"
  add_foreign_key "inventory_items", "items"
  add_foreign_key "inventory_items", "users"
end
