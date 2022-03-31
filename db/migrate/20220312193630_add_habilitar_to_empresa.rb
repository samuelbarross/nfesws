class AddHabilitarToEmpresa < ActiveRecord::Migration
  def change
    add_column :empresas, :habilitar, :boolean, default: true
  end
end
