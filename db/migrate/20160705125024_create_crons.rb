class CreateCrons < ActiveRecord::Migration
  def change
    create_table :crons do |t|
      t.datetime :data
      t.string :cnpj, limit: 14
      t.text :xml_retorno
      t.string :mensagem

      t.timestamps
    end
  end
end
