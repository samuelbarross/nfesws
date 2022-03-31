class FixFieldsPesoLePesoBToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :transportePesoLiquido, :decimal, precision: 12, scale: 3
      t.change :transportePesoBruto, :decimal, precision: 12, scale: 3
    end
  end
  def down
    change_table :nota_fiscais do |t|
      t.change :transportePesoLiquido, :decimal
      t.change :transportePesoBruto, :decimal
    end
  end
end
