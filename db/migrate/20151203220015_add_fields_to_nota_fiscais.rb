class AddFieldsToNotaFiscais < ActiveRecord::Migration
  def change
    add_column :nota_fiscais, :idLoteEvento, :string, limit: 15
    add_column :nota_fiscais, :nrSequencialEvento, :string, limit: 2
    add_column :nota_fiscais, :dataRegistroEvento, :datetime
    add_column :nota_fiscais, :nrProtocoloEvento, :string, limit: 15
  end
end
