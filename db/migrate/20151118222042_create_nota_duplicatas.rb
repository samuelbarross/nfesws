class CreateNotaDuplicatas < ActiveRecord::Migration
  def change
    create_table :nota_duplicatas do |t|
      t.string :nrDuplicata, limit: 60
      t.date :dtVencimento
      t.float :valorDuplicata
      t.references :notaFiscal, index: true

      t.timestamps
    end
  end
end
