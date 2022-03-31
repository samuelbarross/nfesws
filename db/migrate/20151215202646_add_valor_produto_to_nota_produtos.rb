class AddValorProdutoToNotaProdutos < ActiveRecord::Migration
  def change
    add_column :nota_produtos, :valorProduto, :decimal, precision: 10, scale: 2
  end
end
