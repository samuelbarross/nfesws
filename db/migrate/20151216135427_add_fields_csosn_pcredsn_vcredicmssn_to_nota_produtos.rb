class AddFieldsCsosnPcredsnVcredicmssnToNotaProdutos < ActiveRecord::Migration
  def change
    add_column :nota_produtos, :csosn, :string, limit: 3
    add_column :nota_produtos, :p_cred_sn, :decimal, precision: 11, scale: 4
    add_column :nota_produtos, :v_cred_icmssn, :decimal, precision: 10, scale: 2
  end
end
