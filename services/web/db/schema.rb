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

ActiveRecord::Schema[8.1].define(version: 2026_07_08_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "status_conteudo", ["pending", "processing", "done", "failed"]

  create_table "conteudos", force: :cascade do |t|
    t.string "categoria", limit: 50
    t.datetime "created_at", null: false
    t.text "informacoes_adicionais", array: true
    t.decimal "probabilidade", precision: 5, scale: 4
    t.enum "status", default: "pending", null: false, enum_type: "status_conteudo"
    t.text "texto", null: false
    t.string "titulo", limit: 200, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["categoria"], name: "index_conteudos_on_categoria"
    t.index ["created_at"], name: "index_conteudos_on_created_at", order: :desc
    t.index ["informacoes_adicionais"], name: "index_conteudos_on_informacoes_adicionais", using: :gin
    t.index ["status"], name: "index_conteudos_on_status"
    t.index ["titulo"], name: "index_conteudos_on_titulo"
    t.index ["user_id"], name: "index_conteudos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 255, null: false
    t.string "nome", limit: 100, null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "conteudos", "users"
end
