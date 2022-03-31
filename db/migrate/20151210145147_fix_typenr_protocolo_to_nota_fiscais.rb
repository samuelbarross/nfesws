class FixTypenrProtocoloToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :nrProtocoloNfe, :numeric
    end
  end
  def down
    change_table :nota_fiscais do |t|
      t.change :nrProtocoloNfe, :integer
    end
  end
end
