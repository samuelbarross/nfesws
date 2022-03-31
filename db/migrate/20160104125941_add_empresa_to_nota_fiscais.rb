class AddEmpresaToNotaFiscais < ActiveRecord::Migration
  def change
    add_reference :nota_fiscais, :empresa, index: true
  end
end
