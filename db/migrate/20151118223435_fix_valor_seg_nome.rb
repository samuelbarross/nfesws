class FixValorSegNome < ActiveRecord::Migration
  def change
    rename_column :nota_produtos, :valorSeg, :valorSeguro
  end
end
