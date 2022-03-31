class FixFieldValorDuplicataToNotaDuplicatas < ActiveRecord::Migration
  def up
    change_table :nota_duplicatas do |t|
      t.change :valorDuplicata, :decimal, precision: 10, scale: 2
    end
  end
  def down
    change_table :nota_duplicatas do |t|
      t.change :valorDuplicata, :real
    end
  end
end
