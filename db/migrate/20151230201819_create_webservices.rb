class CreateWebservices < ActiveRecord::Migration
  def change
    create_table :webservices do |t|
      t.string :endereco
      t.string :cod_uf

      t.timestamps
    end
  end
end
