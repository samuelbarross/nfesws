class AddCamposIpiToNotaProdutos < ActiveRecord::Migration
  def change
  	# IPI
  	add_column :nota_produtos, :classe_enquadramento_ipi_cigarros_bebidas, :string, limit: 5
  	add_column :nota_produtos, :cnpj_produtor_mercadoria, :string, limit: 14
  	add_column :nota_produtos, :codigo_selo_controle_ipi, :integer
  	add_column :nota_produtos, :qtde_selo_controle_ipi, :integer
  	add_column :nota_produtos, :qtde_total_unidade_padrao, :decimal, precision: 12, scale: 4
  	add_column :nota_produtos, :valor_unidade_tributavel, :decimal, precision: 11, scale: 4

  	#II
  	add_column :nota_produtos, :valor_bc_imposto_importacao, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :valor_despesas_aduaneiras, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :valor_imposto_importacao, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :valor_imposto_iof, :decimal, precision: 13, scale: 2
  end
end
