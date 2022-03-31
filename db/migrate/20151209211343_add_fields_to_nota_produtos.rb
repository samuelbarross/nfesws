class AddFieldsToNotaProdutos < ActiveRecord::Migration
  def change

    add_column :nota_produtos, :modalidadeBCICMS, :integer
    add_column :nota_produtos, :valorAliquotaImpostoICMS, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorTotalTributos, :decimal, precision: 10, scale: 2

    add_column :nota_produtos, :codEnquadramentoIPI, :string, limit: 3
    add_column :nota_produtos, :codSituacaoTribIPI, :string, limit: 2
    add_column :nota_produtos, :valorBCIPI, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorAliquotaIPI, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorIPI, :decimal, precision: 10, scale: 2

    add_column :nota_produtos, :codSituacaoTribPIS, :string, limit: 2
    add_column :nota_produtos, :valorBCPIS, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorAliquotaPIS, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorPIS, :decimal, precision: 10, scale: 2


    add_column :nota_produtos, :codSituacaoTribCofins, :string, limit: 2
    add_column :nota_produtos, :valorBCCofins, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorAliquotaCofins, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorCofins, :decimal, precision: 10, scale: 2
    
  end
end
