class CreateEmpresas < ActiveRecord::Migration
  def change
    create_table :empresas do |t|
      t.string :cnpj, limit: 14
      t.string :nome
      t.string :path_certificado
      t.string :senha_certificado
      t.string :ult_nsu, limit: 20

      t.timestamps
    end
  end
end
