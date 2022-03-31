class AddUfToEmpresas < ActiveRecord::Migration
  def change
  	add_column :empresas, :cod_uf, :integer
  end
end
