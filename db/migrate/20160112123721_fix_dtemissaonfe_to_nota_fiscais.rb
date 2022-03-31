class FixDtemissaonfeToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :dtEmissaoNfe, :date
    end
  end
  def down
    change_table :nota_fiscais do |t|
      t.change :dtEmissaoNfe, :datetime
    end
  end
end
