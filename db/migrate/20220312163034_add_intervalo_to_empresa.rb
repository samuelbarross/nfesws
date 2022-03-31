class AddIntervaloToEmpresa < ActiveRecord::Migration
  def change
    add_column :empresas, :intervalo, :boolean, default: false
  end
end
