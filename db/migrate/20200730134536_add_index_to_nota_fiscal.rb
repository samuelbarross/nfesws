class AddIndexToNotaFiscal < ActiveRecord::Migration
  def change
    add_index :nota_fiscais, :nrChaveNfe
  end
end
