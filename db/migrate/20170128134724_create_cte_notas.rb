class CreateCteNotas < ActiveRecord::Migration
  def change
    create_table :cte_notas do |t|
      t.string :chave_nfe, limit: 50
      t.references :cte, index: true

      t.timestamps
    end
  end
end
