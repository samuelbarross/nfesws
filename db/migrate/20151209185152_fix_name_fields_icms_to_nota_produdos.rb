class FixNameFieldsIcmsToNotaProdudos < ActiveRecord::Migration
  def change
  	rename_column :nota_produtos, :valorBCICMSSTRetido, :valorBCICMS
  	rename_column :nota_produtos, :valorICMSSTRet, :valorICMS
  end
end
