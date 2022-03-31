class FixFieldsToNotaProdutos < ActiveRecord::Migration
  def up
    change_table :nota_produtos do |t|
      t.change :qtdeComercial, :decimal, precision: 11, scale: 4
      t.change :qtdeTributavel, :decimal, precision: 11, scale: 4
      t.change :valorUnitarioComercializacao, :decimal, precision: 10, scale: 2
      t.change :valorUnitarioTributacao, :decimal, precision: 10, scale: 2
      t.change :valorDesconto, :decimal, precision: 10, scale: 2
      t.change :valorTotalFrete, :decimal, precision: 10, scale: 2
      t.change :valorSeguro, :decimal, precision: 10, scale: 2
      t.change :indicadorComposicaoValorTotalNfe, :string, limit: 1
      t.change :itemPedidoCompra, :string, limit: 6
      t.change :valorAproximadoTributos, :decimal, precision: 10, scale: 2
    end
  end
  def down
    change_table :nota_produtos do |t|
      t.change :qtdeComercial, :real
      t.change :qtdeTributavel, :real
      t.change :valorUnitarioComercializacao, :real
      t.change :valorUnitarioTributacao, :real
      t.change :valorDesconto, :real
      t.change :valorTotalFrete, :real
      t.change :valorSeguro, :real
      t.change :indicadorComposicaoValorTotalNfe, :integer
      t.change :itemPedidoCompra, :string, limit: 100
      t.change :valorAproximadoTributos, :real
    end
  end
end
