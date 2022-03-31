class AddValorBcstRetAndValorIcmsstRetToNotaProdutos < ActiveRecord::Migration
  def change
    add_column :nota_produtos, :valorBCSTRet, :decimal, precision: 10, scale: 2
    add_column :nota_produtos, :valorICMSSTRet, :decimal, precision: 10, scale: 2
  end
end
