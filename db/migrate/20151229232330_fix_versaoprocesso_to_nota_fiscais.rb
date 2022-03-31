class FixVersaoprocessoToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :versaoProcesso, :string, limit: 50
    end
  end
  def down
    change_table :nota_fiscais do |t|
		t.change :versaoProcesso, :string, limit: 15
    end
  end
end
