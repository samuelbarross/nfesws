class FixTypeTelEmitenteAndDestinatarioToNotaFiscais < ActiveRecord::Migration
  def self.up
    change_table :nota_fiscais do |t|
      t.change :telefoneEmitente, :string, limit: 14
      t.change :telefoneDestinatario, :string, limit: 14
    end
  end
  def self.down
    change_table :nota_fiscais do |t|
      t.change :telefoneEmitente, :integer
      t.change :telefoneDestinatario, :integer
    end
  end
end
