class CreateNotaFiscais < ActiveRecord::Migration
  def change
    create_table :nota_fiscais do |t|
      t.string :nrChaveNfe, limit: 50
      t.integer :nrNfe
      t.integer :codModeloNfe
      t.string :serieNfe, limit: 10
      t.datetime :dtEmissaoNfe
      t.datetime :dtSaidaEntradaNfe
      t.float :valorTotalNfe
      t.string :nomeEmitente, limit: 60
      t.string :nomeFantasiaEmitente, limit: 60
      t.string :cpfCnpjEmitente, limit: 14
      t.string :logradouroEmitente, limit: 60
      t.string :nrEnderecoEmitente, limit: 60
      t.string :complementoEnderecoEmitente, limit: 60
      t.string :bairroEmitente, limit: 60
      t.integer :cepEmitente
      t.integer :codMunicipioEmitente
      t.integer :telefoneEmitente
      t.string :ufEmitente, limit: 2
      t.integer :codPaisEmitente
      t.string :inscricaoEstadualEmitente, limit: 20
      t.string :inscricaoEstadualSubsTribEmitente, limit: 20
      t.string :inscricaoMunicipalEmitente, limit: 20
      t.integer :codMunicipioFatorGeradorICMSEmitente
      t.integer :cnaeFiscalEmitente
      t.integer :crtEmitente
      t.string :nomeDestinatario, limit: 60
      t.string :cpfCnpjDestinatario, limit: 14
      t.string :logradouroDestinatario, limit: 60
      t.string :nrEnderecoDestinatario, limit: 60
      t.string :bairroDestinatario, limit: 60
      t.integer :cepDestinatario
      t.integer :codMunicipioDestinatario
      t.integer :telefoneDestinatario
      t.string :ufDestinatario, limit: 2
      t.integer :codPaisDestinatario
      t.integer :indicadorIEDestinatario
      t.string :inscricaoEstadualDestinatario, limit: 20
      t.integer :inscricaoSuframa
      t.string :inscricaoMunicipalTomadorServico
      t.string :emailDestinatario, limit: 60
      t.integer :codDestinoOperacaoDestinatario
      t.integer :codConsumidorFinal
      t.integer :codPresencaComprador
      t.integer :codProcessoEmissao
      t.string :versaoProcesso, limit: 15
      t.integer :tipoEmissao
      t.integer :codFinalidadeEmissao
      t.string :naturezaOperacao, limit: 60
      t.integer :tipOperacao
      t.integer :codFormaPagamento
      t.integer :nrProtocoloNfe
      t.datetime :dtRecebimentoNfe
      t.float :valorBaseCalculoICMS
      t.float :valorICMS
      t.float :valorICMSDesonerado
      t.float :valorBaseCalculoICMSST
      t.float :valorICMSSubstituicao
      t.float :valorTotalProduto
      t.float :valorFrete
      t.float :valorSeguro
      t.float :valorOutrasDespesasAcessorias
      t.float :valorTotalIPI
      t.float :valorTotalDesconto
      t.float :valorTotalII
      t.float :valorPIS
      t.float :valorCOFINS
      t.float :valorAproximadoTributos
      t.integer :modalidadeFrete
      t.string :informacoesComplementaresNfe, limit: 6000

      t.timestamps
    end
  end
end
