class CreateConteudos < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL
      CREATE TYPE status_conteudo AS ENUM ('pending', 'processing', 'done', 'failed');
    SQL

    create_table :conteudos do |t|
      t.references :user,              null: false, foreign_key: true
      t.string     :titulo,            null: false, limit: 200
      t.text       :texto,             null: false
      t.string     :categoria,         limit: 50
      t.decimal    :probabilidade,     precision: 5, scale: 4
      t.text       :informacoes_adicionais, array: true
      t.enum       :status,            enum_type: :status_conteudo, default: "pending", null: false
      t.timestamps
    end

    add_index :conteudos, :titulo
    add_index :conteudos, :informacoes_adicionais, using: :gin
    add_index :conteudos, :status
    add_index :conteudos, :created_at, order: { created_at: :desc }
    add_index :conteudos, :categoria
  end

  def down
    drop_table :conteudos
    execute <<-SQL
      DROP TYPE status_conteudo;
    SQL
  end
end
