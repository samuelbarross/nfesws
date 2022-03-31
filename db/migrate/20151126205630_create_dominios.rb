class CreateDominios < ActiveRecord::Migration
  def change
    create_table :dominios do |t|
      t.string :descricao, limit: 80

      t.timestamps
    end
  end
end
