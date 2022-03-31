class AddCampoMunicipioDestinatarioNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :municipioDestinatario, :string, limit: 60
  end
end
