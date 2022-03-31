class AddNsuToNotaFiscal < ActiveRecord::Migration
  def change
    add_column :nota_fiscais, :nsu, :string, limit: 20
  end
end
