class CreateDominioValores < ActiveRecord::Migration
  def change
    create_table :dominio_valores do |t|
      t.string :codigo, limit: 10
      t.string :descricao, limit: 80
      t.references :dominio, index: true

      t.timestamps
    end
  end
end
