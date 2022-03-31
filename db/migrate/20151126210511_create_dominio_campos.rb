class CreateDominioCampos < ActiveRecord::Migration
  def change
    create_table :dominio_campos do |t|
      t.string :descricao, limit: 20
      t.references :dominio, index: true

      t.timestamps
    end
  end
end
