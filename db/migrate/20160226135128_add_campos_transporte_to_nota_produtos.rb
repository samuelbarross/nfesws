class AddCamposTransporteToNotaProdutos < ActiveRecord::Migration
  def change
    # Transporte
    add_column :nota_fiscais, :cnpj_transportador, :string, limit: 14
    add_column :nota_fiscais, :cpf_transportador, :string, limit: 11
    add_column :nota_fiscais, :nome_transportador, :string, limit: 60
    add_column :nota_fiscais, :ie_transportador, :string, limit: 14
    add_column :nota_fiscais, :endereco_transportador, :string, limit: 60
    add_column :nota_fiscais, :municipio_transportador, :string, limit: 30
    add_column :nota_fiscais, :uf_transportador, :string, limit: 2
    # ICMS transporte
    add_column :nota_fiscais, :valor_servico_transporte, :decimal, precision: 13, scale: 2
    add_column :nota_fiscais, :valor_bc_retencao_icms_transporte, :decimal, precision: 13, scale: 2
    add_column :nota_fiscais, :aliquota_retencao_icms_transporte, :decimal, precision: 7, scale: 4
    add_column :nota_fiscais, :valor_icms_retido_transporte, :decimal, precision: 13, scale: 2
    add_column :nota_fiscais, :cfop_transporte, :integer
    add_column :nota_fiscais, :codigo_municipio_fator_gerador_icms_transporte, :string, limit: 10
  end
end
