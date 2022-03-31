class FixFieldsCodigosToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :codFormaPagamento, :string, limit: 1
    end
  end
  def down
    change_table :nota_fiscais do |t|
      t.change :codFormaPagamento, :integer
    end
  end
end
