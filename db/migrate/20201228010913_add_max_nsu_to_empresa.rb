class AddMaxNsuToEmpresa < ActiveRecord::Migration
  def change
    add_column :empresas, :max_nsu, :string, limit: 20
  end
end
