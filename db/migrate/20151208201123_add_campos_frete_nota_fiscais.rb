class AddCamposFreteNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :transporteQtde, :integer
    add_column :nota_fiscais, :transporteEspecie, :string, limit: 60
    add_column :nota_fiscais, :transporteMarcaDosVolumes, :string, limit: 60
    add_column :nota_fiscais, :transporteNumeracao, :string, limit: 60
    add_column :nota_fiscais, :transportePesoLiquido, :decimal
    add_column :nota_fiscais, :transportePesoBruto, :decimal
  end
end
