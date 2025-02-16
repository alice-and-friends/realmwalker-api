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

ActiveRecord::Schema[7.0].define(version: 700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "conquests", force: :cascade do |t|
    t.uuid "realm_location_id"
    t.string "realm_location_type", null: false
    t.bigint "monster_id"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["monster_id"], name: "index_conquests_on_monster_id"
    t.index ["realm_location_id"], name: "index_conquests_on_realm_location_id"
    t.index ["user_id"], name: "index_conquests_on_user_id"
  end

  create_table "dungeon_searches", force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "realm_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["realm_location_id"], name: "index_dungeon_searches_on_realm_location_id"
    t.index ["user_id", "realm_location_id"], name: "index_dungeon_searches_on_user_id_and_realm_location_id", unique: true
    t.index ["user_id"], name: "index_dungeon_searches_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "start_at"
    t.datetime "finish_at"
    t.boolean "announce", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventories", force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "realm_location_id"
    t.integer "gold", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["realm_location_id"], name: "index_inventories_on_realm_location_id", unique: true
    t.index ["user_id"], name: "index_inventories_on_user_id", unique: true
  end

  create_table "inventory_items", force: :cascade do |t|
    t.bigint "inventory_id", null: false
    t.bigint "item_id", null: false
    t.bigint "writing_id"
    t.boolean "is_equipped", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_inventory_items_on_inventory_id"
    t.index ["item_id"], name: "index_inventory_items_on_item_id"
    t.index ["writing_id"], name: "index_inventory_items_on_writing_id"
  end

  create_table "inventory_transactions", force: :cascade do |t|
    t.string "description", null: false
    t.jsonb "create_items", default: []
    t.jsonb "transfer_items", default: []
    t.jsonb "destroy_items", default: []
    t.jsonb "add_gold", default: []
    t.jsonb "transfer_gold", default: []
    t.jsonb "subtract_gold", default: []
    t.string "status", default: "staged", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.string "icon", null: false
    t.boolean "stackable", default: false, null: false
    t.string "rarity"
    t.integer "dropped_by_monsters", default: [], array: true
    t.integer "drop_max_amount", default: 1, null: false
    t.boolean "two_handed", default: false, null: false
    t.integer "attack_bonus", limit: 2, default: 0
    t.integer "defense_bonus", limit: 2, default: 0
    t.string "classification_bonus"
    t.integer "classification_attack_bonus", limit: 2, default: 0
    t.integer "classification_defense_bonus", limit: 2, default: 0
    t.float "xp_bonus", default: 0.0
    t.float "loot_bonus", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_items_on_name", unique: true
  end

  create_table "monster_items", force: :cascade do |t|
    t.bigint "monster_id", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_monster_items_on_item_id"
    t.index ["monster_id", "item_id"], name: "index_monster_items_on_monster_id_and_item_id", unique: true
    t.index ["monster_id"], name: "index_monster_items_on_monster_id"
  end

  create_table "monsters", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.integer "level", null: false
    t.string "classification", null: false
    t.boolean "auto_spawn", default: true, null: false
    t.string "spawn_time"
    t.text "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_monsters_on_name", unique: true
  end

  create_table "npcs_trade_offer_lists", id: false, force: :cascade do |t|
    t.uuid "npc_id"
    t.bigint "trade_offer_list_id"
    t.index ["npc_id"], name: "index_npcs_trade_offer_lists_on_npc_id"
    t.index ["trade_offer_list_id"], name: "index_npcs_trade_offer_lists_on_trade_offer_list_id"
  end

  create_table "portraits", force: :cascade do |t|
    t.string "name"
    t.string "species", default: [], array: true
    t.string "genders", default: [], array: true
    t.string "groups", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "real_world_locations", force: :cascade do |t|
    t.string "type", null: false
    t.string "ext_id"
    t.geography "coordinates", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "region", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.string "timezone"
    t.jsonb "tags"
    t.string "source_file"
    t.integer "relevance_grade", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coordinates"], name: "index_real_world_locations_on_coordinates", using: :gist
    t.index ["ext_id"], name: "index_real_world_locations_on_ext_id", unique: true
    t.index ["latitude", "longitude"], name: "index_real_world_locations_on_latitude_and_longitude", unique: true
    t.index ["region"], name: "index_real_world_locations_on_region"
    t.index ["type"], name: "index_real_world_locations_on_type"
  end

  create_table "realm_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type"
    t.string "sub_type"
    t.bigint "real_world_location_id", null: false
    t.geography "coordinates", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "timezone"
    t.string "region", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "owner_id"
    t.string "species"
    t.string "gender", limit: 1
    t.string "role"
    t.bigint "portrait_id"
    t.string "status"
    t.integer "level"
    t.bigint "monster_id"
    t.integer "hp"
    t.datetime "defeated_at"
    t.string "expiry_job_id"
    t.datetime "expires_at"
    t.string "runestone_id"
    t.bigint "writing_id"
    t.datetime "captured_at"
    t.index ["coordinates"], name: "index_realm_locations_on_coordinates", using: :gist
    t.index ["monster_id"], name: "index_realm_locations_on_monster_id"
    t.index ["owner_id"], name: "index_realm_locations_on_owner_id", unique: true
    t.index ["portrait_id"], name: "index_realm_locations_on_portrait_id"
    t.index ["real_world_location_id"], name: "index_realm_locations_on_real_world_location_id", unique: true
    t.index ["region"], name: "index_realm_locations_on_region"
    t.index ["role"], name: "index_realm_locations_on_role"
    t.index ["status"], name: "index_realm_locations_on_status"
    t.index ["type"], name: "index_realm_locations_on_type"
    t.index ["writing_id"], name: "index_realm_locations_on_writing_id"
  end

  create_table "spooks", force: :cascade do |t|
    t.uuid "npc_id", null: false
    t.uuid "dungeon_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dungeon_id"], name: "index_spooks_on_dungeon_id"
    t.index ["npc_id"], name: "index_spooks_on_npc_id"
  end

  create_table "trade_offer_lists", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trade_offers", force: :cascade do |t|
    t.bigint "item_id"
    t.integer "buy_offer"
    t.integer "sell_offer"
    t.bigint "trade_offer_list_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_trade_offers_on_item_id"
    t.index ["trade_offer_list_id"], name: "index_trade_offers_on_trade_offer_list_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "auth0_user_id", null: false
    t.json "auth0_user_data"
    t.json "preferences"
    t.text "access_token"
    t.datetime "access_token_expires_at", precision: nil
    t.string "display_name"
    t.bigint "portrait_id"
    t.integer "xp", default: 0
    t.integer "level", default: 1
    t.text "ability_score_improvements", default: [], array: true
    t.text "achievements", default: [], array: true
    t.text "discovered_runestones", default: [], array: true
    t.datetime "reward_claimed_at", precision: nil
    t.integer "reward_streak", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth0_user_id"], name: "index_users_on_auth0_user_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["portrait_id"], name: "index_users_on_portrait_id"
  end

  create_table "writings", force: :cascade do |t|
    t.string "title", default: "", null: false
    t.string "author_name", default: "", null: false
    t.text "body", default: "", null: false
    t.uuid "author_id"
    t.boolean "core_content", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_writings_on_author_id"
  end

  add_foreign_key "conquests", "monsters"
  add_foreign_key "conquests", "realm_locations"
  add_foreign_key "conquests", "users"
  add_foreign_key "dungeon_searches", "realm_locations"
  add_foreign_key "dungeon_searches", "users"
  add_foreign_key "inventory_items", "inventories"
  add_foreign_key "inventory_items", "items"
  add_foreign_key "inventory_items", "writings"
  add_foreign_key "monster_items", "items"
  add_foreign_key "monster_items", "monsters"
  add_foreign_key "npcs_trade_offer_lists", "realm_locations", column: "npc_id"
  add_foreign_key "realm_locations", "portraits"
  add_foreign_key "realm_locations", "users", column: "owner_id"
  add_foreign_key "realm_locations", "writings"
  add_foreign_key "spooks", "realm_locations", column: "dungeon_id"
  add_foreign_key "spooks", "realm_locations", column: "npc_id"
  add_foreign_key "trade_offers", "items"
  add_foreign_key "users", "portraits"
  add_foreign_key "writings", "users", column: "author_id"
end
