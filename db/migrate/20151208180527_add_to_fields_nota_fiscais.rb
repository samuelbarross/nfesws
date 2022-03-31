class AddToFieldsNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :paisEmitente, :string, limit: 50
  	add_column :nota_fiscais, :paisDestinatario, :string, limit: 50
  end
end
