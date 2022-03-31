class CreateNotaProdutos < ActiveRecord::Migration
  def change
    create_table :nota_produtos do |t|
      t.integer :nrItem
      t.string :descricao, limit: 120
      t.float :qtdeComercial
      t.float :qtdeTributavel
      t.string :unidadeComercial, limit: 6
      t.string :unidadeTributavel, limit: 6
      t.float :valorUnitarioComercializacao
      t.float :valorUnitarioTributacao
      t.string :codProduto, limit: 40
      t.string :codNCM, limit: 20
      t.string :codExTIPI, limit: 20
      t.string :cfop, limit: 10
      t.string :outrasDespesasAcessorias, limit: 20
      t.float :valorDesconto
      t.float :valorTotalFrete
      t.float :valorSeg
      t.integer :indicadorComposicaoValorTotalNfe
      t.string :codEANComercial, limit: 20
      t.string :codEANTributavel, limit: 20
      t.integer :nrPedidoCompra, limit: 5
      t.string :itemPedidoCompra, limit: 100
      t.float :valorAproximadoTributos
      t.integer :nrFCI
      t.integer :origemMercadoria
      t.integer :codTributacaoICMS
      t.float :valorBCICMSSTRetido
      t.float :valorICMSSTRet
      t.string :pisCST, limit: 4
      t.string :cofinsCST, limit: 4
      t.string :informacoesAdicionaisProduto, limit: 500
      t.references :notaFiscal, index: true

      t.timestamps
    end
  end
end
