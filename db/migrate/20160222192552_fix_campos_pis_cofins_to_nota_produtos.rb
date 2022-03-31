class FixCamposPisCofinsToNotaProdutos < ActiveRecord::Migration
  def up
    change_table :nota_produtos do |t|
     # PIS	codSituacaoTribPIS
	   t.change :valorBCPIS, :decimal, precision: 13, scale: 2
	   t.change :valorAliquotaPIS, :decimal, precision: 7, scale: 4
	   t.change :valorPIS, :decimal, precision: 13, scale: 2
	   # COFINS
	   t.change :valorBCCofins, :decimal, precision: 13, scale: 2
	   t.change :valorAliquotaCofins, :decimal, precision: 7, scale: 4
	   t.change :valorCofins, :decimal, precision: 13, scale: 2
    end
  end  
end