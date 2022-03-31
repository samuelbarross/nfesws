class FixCamposIcmsToNotaProdutos < ActiveRecord::Migration
  def up
    change_table :nota_produtos do |t|
       # ICMS
	   t.change :valorBCICMS, :decimal, precision: 13, scale: 2
	   t.change :valorAliquotaImpostoICMS, :decimal, precision: 7, scale: 4
	   t.change :valorICMS, :decimal, precision: 13, scale: 2
	   t.change :valorBCSTRet, :decimal, precision: 13, scale: 2
	   t.change :valorICMSSTRet, :decimal, precision: 13, scale: 2
	   t.change :csosn, :integer
	   t.change :p_cred_sn, :decimal, precision: 7, scale: 4
	   t.change :v_cred_icmssn, :decimal, precision: 13, scale: 2
    end	
  end
end
