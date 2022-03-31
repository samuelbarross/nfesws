class FixCamposIpiToNotaProdutos < ActiveRecord::Migration
  def up
    change_table :nota_produtos do |t|
       # IPI
	   t.change :valorBCIPI, :decimal, precision: 13, scale: 2
	   t.change :valorAliquotaIPI, :decimal, precision: 7, scale: 4
	   t.change :valorIPI, :decimal, precision: 13, scale: 2
    end	
  end
end
