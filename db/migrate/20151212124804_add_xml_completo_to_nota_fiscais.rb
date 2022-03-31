class AddXmlCompletoToNotaFiscais < ActiveRecord::Migration
  def change
    add_column :nota_fiscais, :xml_completo, :text
  end
end
