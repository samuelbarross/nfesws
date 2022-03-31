class FixValorTotalNfeToNotaFiscais < ActiveRecord::Migration
  def up
    change_table :nota_fiscais do |t|
      t.change :valorTotalNfe, :decimal, precision: 18, scale: 2
    end
  end  
end
