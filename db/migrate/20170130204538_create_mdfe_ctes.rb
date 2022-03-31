class CreateMdfeCtes < ActiveRecord::Migration
  def change
    create_table :mdfe_ctes do |t|
      t.string :chave_cte, limit: 44
      t.references :mdfe, index: true

      t.timestamps
    end
  end
end
