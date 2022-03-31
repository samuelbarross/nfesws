class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :acao
      t.references :user, index: true
      t.references :nota_fiscal, index: true

      t.timestamps
    end
  end
end
