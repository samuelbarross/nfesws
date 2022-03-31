class AddToFieldNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :municipioEmitente, :string, limit: 50
  end
end
