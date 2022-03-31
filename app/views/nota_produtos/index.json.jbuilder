json.array!(@nota_produtos) do |nota_produto|
  json.extract! nota_produto, :id, :nrItem, :descricao, :qtdeComercial, :qtdeTributavel, :unidadeComercial, :unidadeTributavel, :valorUnitarioComercializacao, :float, :codProduto, :codNCM, :codExTIPI, :cfop, :outrasDespesasAcessorias, :valorDesconto, :valorTotalFrete, :valorSeg, :indicadorComposicaoValorTotalNfe, :codEANComercial, :codEANTributavel, :nrPedidoCompra, :itemPedidoCompra, :valorAproximadoTributos, :nrFCI, :origemMercadoria, :codTributacaoICMS, :valorBCICMSSTRetido, :valorICMSSTRet, :pisCST, :cofinsCST, :informacoesAdicionaisProduto, :notaFiscal_id
  json.url nota_produto_url(nota_produto, format: :json)
end
