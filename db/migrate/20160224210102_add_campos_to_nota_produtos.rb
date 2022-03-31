class AddCamposToNotaProdutos < ActiveRecord::Migration
  def change
  	add_column :nota_produtos, :percentual_reducao_bc_icms, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :modalidade_determinacao_bc_icms_st, :integer
  	add_column :nota_produtos, :valor_bc_icms_st, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :aliquota_icms_st, :decimal, precision: 7, scale: 4
  	add_column :nota_produtos, :valor_icms_st, :decimal, precision: 13, scale: 2
  	add_column :nota_produtos, :percentual_reducao_bc_icms_st, :decimal, precision: 7, scale: 4
  	add_column :nota_produtos, :percentual_margem_valor_adicionado_icms_st, :decimal, precision: 7, scale: 4
  end
end
