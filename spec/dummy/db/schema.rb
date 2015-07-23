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

ActiveRecord::Schema.define(version: 20150608151718) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "pig_activity_items", force: true do |t|
    t.integer  "user_id"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "parent_resource_id"
    t.string   "parent_resource_type"
    t.string   "text"
    t.datetime "created_at"
  end

  add_index "pig_activity_items", ["parent_resource_type", "parent_resource_id"], name: "parent_resource_index", using: :btree
  add_index "pig_activity_items", ["resource_type", "resource_id"], name: "resource_index", using: :btree
  add_index "pig_activity_items", ["user_id"], name: "index_pig_activity_items_on_user_id", using: :btree

  create_table "pig_content_attributes", force: true do |t|
    t.integer "content_type_id"
    t.string  "slug"
    t.string  "name"
    t.text    "description"
    t.string  "field_type"
    t.integer "limit_quantity"
    t.string  "limit_unit"
    t.integer "position",                 default: 0
    t.boolean "required",                 default: false
    t.boolean "meta",                     default: false
    t.string  "meta_tag_name"
    t.integer "default_attribute_id"
    t.text    "sir_trevor_settings"
    t.integer "resource_content_type_id"
  end

  add_index "pig_content_attributes", ["content_type_id"], name: "index_pig_content_attributes_on_content_type_id", using: :btree

  create_table "pig_content_chunks", force: true do |t|
    t.integer  "content_package_id"
    t.integer  "content_attribute_id"
    t.text     "value"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_content_chunks", ["content_package_id", "content_attribute_id"], name: "index_content_on_package_attribute", unique: true, using: :btree

  create_table "pig_content_packages", force: true do |t|
    t.string   "slug"
    t.string   "name"
    t.integer  "content_type_id"
    t.integer  "position",         default: 0
    t.integer  "parent_id"
    t.integer  "author_id"
    t.integer  "requested_by_id"
    t.string   "status",           default: "draft"
    t.boolean  "logged_in_only",   default: false
    t.boolean  "hide_from_robots", default: false
    t.text     "notes"
    t.date     "due_date"
    t.integer  "review_frequency"
    t.date     "next_review"
    t.date     "publish_at"
    t.date     "published_at"
    t.datetime "deleted_at"
    t.string   "meta_title"
    t.text     "meta_description"
    t.string   "meta_keywords"
    t.string   "meta_image_uid"
    t.string   "meta_image_name"
    t.json     "json_content",     default: {},      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_content_packages", ["parent_id"], name: "index_pig_content_packages_on_parent_id", using: :btree
  add_index "pig_content_packages", ["slug"], name: "index_pig_content_packages_on_slug", using: :btree

  create_table "pig_content_packages_personas", id: false, force: true do |t|
    t.integer "content_package_id"
    t.integer "persona_id"
  end

  add_index "pig_content_packages_personas", ["content_package_id"], name: "index_pig_content_packages_personas_on_content_package_id", using: :btree

  create_table "pig_content_types", force: true do |t|
    t.string  "name"
    t.text    "description"
    t.boolean "singleton",    default: false
    t.string  "package_name"
    t.boolean "viewless",     default: false
    t.string  "view_name"
    t.boolean "use_workflow", default: false
  end

  create_table "pig_meta_data", force: true do |t|
    t.string   "page_slug"
    t.string   "title"
    t.text     "description"
    t.string   "keywords"
    t.string   "image_uid"
    t.string   "image_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pig_navigation_items", force: true do |t|
    t.integer  "parent_id"
    t.integer  "position",      default: 0
    t.string   "item_type"
    t.string   "title"
    t.text     "description"
    t.string   "image_uid"
    t.string   "logo_uid"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_navigation_items", ["parent_id"], name: "index_pig_navigation_items_on_parent_id", using: :btree

  create_table "pig_permalinks", force: true do |t|
    t.string   "path"
    t.string   "full_path"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.boolean  "active",        default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_permalinks", ["full_path"], name: "index_pig_permalinks_on_full_path", using: :btree
  add_index "pig_permalinks", ["path"], name: "index_pig_permalinks_on_path", using: :btree

  create_table "pig_persona_groups", force: true do |t|
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pig_personas", force: true do |t|
    t.integer  "group_id"
    t.string   "name"
    t.string   "category"
    t.integer  "age"
    t.text     "summary"
    t.text     "benefit_1"
    t.text     "benefit_2"
    t.text     "benefit_3"
    t.text     "benefit_4"
    t.string   "image_uid"
    t.string   "file_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_personas", ["group_id"], name: "index_pig_personas_on_group_id", using: :btree

  create_table "pig_resource_tag_categories", force: true do |t|
    t.integer "tag_category_id"
    t.integer "taggable_resource_id"
    t.string  "taggable_resource_type"
  end

  add_index "pig_resource_tag_categories", ["tag_category_id"], name: "index_pig_resource_tag_categories_on_tag_category_id", using: :btree
  add_index "pig_resource_tag_categories", ["taggable_resource_id", "taggable_resource_type"], name: "index_resource_id_and_type", using: :btree
  add_index "pig_resource_tag_categories", ["taggable_resource_id"], name: "index_pig_resource_tag_categories_on_taggable_resource_id", using: :btree

  create_table "pig_sir_trevor_images", force: true do |t|
    t.text    "image_uid"
    t.text    "sir_trevor_uid"
    t.text    "filename"
    t.integer "content_package_id"
  end

  create_table "pig_tag_categories", force: true do |t|
    t.string "name"
    t.string "slug"
  end

  create_table "pig_users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "bio"
    t.string   "role"
    t.boolean  "active",                 default: true
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "image_uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pig_users", ["email"], name: "index_pig_users_on_email", unique: true, using: :btree
  add_index "pig_users", ["reset_password_token"], name: "index_pig_users_on_reset_password_token", unique: true, using: :btree

  create_table "taggings", force: true do |t|
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

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

end
