class AddDanfeToNotaFiscais < ActiveRecord::Migration
  def change
    add_column :nota_fiscais, :danfe, :text
  end
end
