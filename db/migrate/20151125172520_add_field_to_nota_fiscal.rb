class AddFieldToNotaFiscal < ActiveRecord::Migration
  def change
    add_column :nota_fiscais, :codSituacaoNfe, :integer
    add_column :nota_fiscais, :codSituacaoManifestacaoDestinatario, :integer
  end
end
