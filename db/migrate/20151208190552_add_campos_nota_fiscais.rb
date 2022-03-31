class AddCamposNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :complementoEnderecoDestinatario, :string, limit: 60
  end
end
