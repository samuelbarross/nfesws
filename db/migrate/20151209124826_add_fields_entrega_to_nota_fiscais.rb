class AddFieldsEntregaToNotaFiscais < ActiveRecord::Migration
  def change
  	add_column :nota_fiscais, :entregaCpfCnpj, :string, limit: 14
    add_column :nota_fiscais, :entregaLogradouro, :string, limit: 60
    add_column :nota_fiscais, :entregaNumero, :string, limit: 60
    add_column :nota_fiscais, :entregaComplemento, :string, limit: 60
    add_column :nota_fiscais, :entregaBairro, :string, limit: 60
    add_column :nota_fiscais, :entregaMunicipio, :string, limit: 60
    add_column :nota_fiscais, :entregaUF, :string, limit: 2
  end
end
