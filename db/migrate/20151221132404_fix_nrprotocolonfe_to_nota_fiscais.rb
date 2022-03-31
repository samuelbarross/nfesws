class FixNrprotocolonfeToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :nrProtocoloNfe, :string, limit: 20
    end
  end
  def down
    change_table :nota_fiscais do |t|
      t.change :nrProtocoloNfe, :numeric
    end
  end
end
