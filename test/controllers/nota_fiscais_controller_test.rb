require 'test_helper'

class NotaFiscaisControllerTest < ActionController::TestCase
  setup do
    @nota_fiscal = nota_fiscais(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:nota_fiscais)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create nota_fiscal" do
    assert_difference('NotaFiscal.count') do
      post :create, nota_fiscal: { bairroDestinatario: @nota_fiscal.bairroDestinatario, bairroEmitente: @nota_fiscal.bairroEmitente, cepDestinatario: @nota_fiscal.cepDestinatario, cepEmitente: @nota_fiscal.cepEmitente, cnaeFiscalEmitente: @nota_fiscal.cnaeFiscalEmitente, codConsumidorFinal: @nota_fiscal.codConsumidorFinal, codDestinoOperacaoDestinatario: @nota_fiscal.codDestinoOperacaoDestinatario, codFinalidadeEmissao: @nota_fiscal.codFinalidadeEmissao, codFormaPagamento: @nota_fiscal.codFormaPagamento, codModeloNfe: @nota_fiscal.codModeloNfe, codMunicipioDestinatario: @nota_fiscal.codMunicipioDestinatario, codMunicipioEmitente: @nota_fiscal.codMunicipioEmitente, codMunicipioFatorGeradorICMSEmitente: @nota_fiscal.codMunicipioFatorGeradorICMSEmitente, codPaisDestinatario: @nota_fiscal.codPaisDestinatario, codPaisEmitente: @nota_fiscal.codPaisEmitente, codPresencaComprador: @nota_fiscal.codPresencaComprador, codProcessoEmissao: @nota_fiscal.codProcessoEmissao, complementoEnderecoEmitente: @nota_fiscal.complementoEnderecoEmitente, cpfCnpjDestinatario: @nota_fiscal.cpfCnpjDestinatario, cpfCnpjEmitente: @nota_fiscal.cpfCnpjEmitente, crtEmitente: @nota_fiscal.crtEmitente, dtEmissaoNfe: @nota_fiscal.dtEmissaoNfe, dtRecebimentoNfe: @nota_fiscal.dtRecebimentoNfe, dtSaidaEntradaNfe: @nota_fiscal.dtSaidaEntradaNfe, emailDestinatario: @nota_fiscal.emailDestinatario, indicadorIEDestinatario: @nota_fiscal.indicadorIEDestinatario, informacoesComplementaresNfe: @nota_fiscal.informacoesComplementaresNfe, inscricaoEstadualDestinatario: @nota_fiscal.inscricaoEstadualDestinatario, inscricaoEstadualEmitente: @nota_fiscal.inscricaoEstadualEmitente, inscricaoEstadualSubsTribEmitente: @nota_fiscal.inscricaoEstadualSubsTribEmitente, inscricaoMunicipalEmitente: @nota_fiscal.inscricaoMunicipalEmitente, inscricaoMunicipalTomadorServico: @nota_fiscal.inscricaoMunicipalTomadorServico, inscricaoSuframa: @nota_fiscal.inscricaoSuframa, logradouroDestinatario: @nota_fiscal.logradouroDestinatario, logradouroEmitente: @nota_fiscal.logradouroEmitente, modalidadeFrete: @nota_fiscal.modalidadeFrete, naturezaOperacao: @nota_fiscal.naturezaOperacao, nomeDestinatario: @nota_fiscal.nomeDestinatario, nomeEmitente: @nota_fiscal.nomeEmitente, nomeFantasiaEmitente: @nota_fiscal.nomeFantasiaEmitente, nrChaveNfe: @nota_fiscal.nrChaveNfe, nrEnderecoDestinatario: @nota_fiscal.nrEnderecoDestinatario, nrEnderecoEmitente: @nota_fiscal.nrEnderecoEmitente, nrNfe: @nota_fiscal.nrNfe, nrProtocoloNfe: @nota_fiscal.nrProtocoloNfe, serieNfe: @nota_fiscal.serieNfe, telefoneDestinatario: @nota_fiscal.telefoneDestinatario, telefoneEmitente: @nota_fiscal.telefoneEmitente, tipOperacao: @nota_fiscal.tipOperacao, tipoEmissao: @nota_fiscal.tipoEmissao, ufDestinatario: @nota_fiscal.ufDestinatario, ufEmitente: @nota_fiscal.ufEmitente, valorAproximadoTributos: @nota_fiscal.valorAproximadoTributos, valorBaseCalculoICMS: @nota_fiscal.valorBaseCalculoICMS, valorBaseCalculoICMSST: @nota_fiscal.valorBaseCalculoICMSST, valorCOFINS: @nota_fiscal.valorCOFINS, valorFrete: @nota_fiscal.valorFrete, valorICMS: @nota_fiscal.valorICMS, valorICMSDesonerado: @nota_fiscal.valorICMSDesonerado, valorICMSSubstituicao: @nota_fiscal.valorICMSSubstituicao, valorOutrasDespesasAcessorias: @nota_fiscal.valorOutrasDespesasAcessorias, valorPIS: @nota_fiscal.valorPIS, valorSeguro: @nota_fiscal.valorSeguro, valorTotalDesconto: @nota_fiscal.valorTotalDesconto, valorTotalII: @nota_fiscal.valorTotalII, valorTotalIPI: @nota_fiscal.valorTotalIPI, valorTotalNfe: @nota_fiscal.valorTotalNfe, valorTotalProduto: @nota_fiscal.valorTotalProduto, versaoProcesso: @nota_fiscal.versaoProcesso }
    end

    assert_redirected_to nota_fiscal_path(assigns(:nota_fiscal))
  end

  test "should show nota_fiscal" do
    get :show, id: @nota_fiscal
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @nota_fiscal
    assert_response :success
  end

  test "should update nota_fiscal" do
    patch :update, id: @nota_fiscal, nota_fiscal: { bairroDestinatario: @nota_fiscal.bairroDestinatario, bairroEmitente: @nota_fiscal.bairroEmitente, cepDestinatario: @nota_fiscal.cepDestinatario, cepEmitente: @nota_fiscal.cepEmitente, cnaeFiscalEmitente: @nota_fiscal.cnaeFiscalEmitente, codConsumidorFinal: @nota_fiscal.codConsumidorFinal, codDestinoOperacaoDestinatario: @nota_fiscal.codDestinoOperacaoDestinatario, codFinalidadeEmissao: @nota_fiscal.codFinalidadeEmissao, codFormaPagamento: @nota_fiscal.codFormaPagamento, codModeloNfe: @nota_fiscal.codModeloNfe, codMunicipioDestinatario: @nota_fiscal.codMunicipioDestinatario, codMunicipioEmitente: @nota_fiscal.codMunicipioEmitente, codMunicipioFatorGeradorICMSEmitente: @nota_fiscal.codMunicipioFatorGeradorICMSEmitente, codPaisDestinatario: @nota_fiscal.codPaisDestinatario, codPaisEmitente: @nota_fiscal.codPaisEmitente, codPresencaComprador: @nota_fiscal.codPresencaComprador, codProcessoEmissao: @nota_fiscal.codProcessoEmissao, complementoEnderecoEmitente: @nota_fiscal.complementoEnderecoEmitente, cpfCnpjDestinatario: @nota_fiscal.cpfCnpjDestinatario, cpfCnpjEmitente: @nota_fiscal.cpfCnpjEmitente, crtEmitente: @nota_fiscal.crtEmitente, dtEmissaoNfe: @nota_fiscal.dtEmissaoNfe, dtRecebimentoNfe: @nota_fiscal.dtRecebimentoNfe, dtSaidaEntradaNfe: @nota_fiscal.dtSaidaEntradaNfe, emailDestinatario: @nota_fiscal.emailDestinatario, indicadorIEDestinatario: @nota_fiscal.indicadorIEDestinatario, informacoesComplementaresNfe: @nota_fiscal.informacoesComplementaresNfe, inscricaoEstadualDestinatario: @nota_fiscal.inscricaoEstadualDestinatario, inscricaoEstadualEmitente: @nota_fiscal.inscricaoEstadualEmitente, inscricaoEstadualSubsTribEmitente: @nota_fiscal.inscricaoEstadualSubsTribEmitente, inscricaoMunicipalEmitente: @nota_fiscal.inscricaoMunicipalEmitente, inscricaoMunicipalTomadorServico: @nota_fiscal.inscricaoMunicipalTomadorServico, inscricaoSuframa: @nota_fiscal.inscricaoSuframa, logradouroDestinatario: @nota_fiscal.logradouroDestinatario, logradouroEmitente: @nota_fiscal.logradouroEmitente, modalidadeFrete: @nota_fiscal.modalidadeFrete, naturezaOperacao: @nota_fiscal.naturezaOperacao, nomeDestinatario: @nota_fiscal.nomeDestinatario, nomeEmitente: @nota_fiscal.nomeEmitente, nomeFantasiaEmitente: @nota_fiscal.nomeFantasiaEmitente, nrChaveNfe: @nota_fiscal.nrChaveNfe, nrEnderecoDestinatario: @nota_fiscal.nrEnderecoDestinatario, nrEnderecoEmitente: @nota_fiscal.nrEnderecoEmitente, nrNfe: @nota_fiscal.nrNfe, nrProtocoloNfe: @nota_fiscal.nrProtocoloNfe, serieNfe: @nota_fiscal.serieNfe, telefoneDestinatario: @nota_fiscal.telefoneDestinatario, telefoneEmitente: @nota_fiscal.telefoneEmitente, tipOperacao: @nota_fiscal.tipOperacao, tipoEmissao: @nota_fiscal.tipoEmissao, ufDestinatario: @nota_fiscal.ufDestinatario, ufEmitente: @nota_fiscal.ufEmitente, valorAproximadoTributos: @nota_fiscal.valorAproximadoTributos, valorBaseCalculoICMS: @nota_fiscal.valorBaseCalculoICMS, valorBaseCalculoICMSST: @nota_fiscal.valorBaseCalculoICMSST, valorCOFINS: @nota_fiscal.valorCOFINS, valorFrete: @nota_fiscal.valorFrete, valorICMS: @nota_fiscal.valorICMS, valorICMSDesonerado: @nota_fiscal.valorICMSDesonerado, valorICMSSubstituicao: @nota_fiscal.valorICMSSubstituicao, valorOutrasDespesasAcessorias: @nota_fiscal.valorOutrasDespesasAcessorias, valorPIS: @nota_fiscal.valorPIS, valorSeguro: @nota_fiscal.valorSeguro, valorTotalDesconto: @nota_fiscal.valorTotalDesconto, valorTotalII: @nota_fiscal.valorTotalII, valorTotalIPI: @nota_fiscal.valorTotalIPI, valorTotalNfe: @nota_fiscal.valorTotalNfe, valorTotalProduto: @nota_fiscal.valorTotalProduto, versaoProcesso: @nota_fiscal.versaoProcesso }
    assert_redirected_to nota_fiscal_path(assigns(:nota_fiscal))
  end

  test "should destroy nota_fiscal" do
    assert_difference('NotaFiscal.count', -1) do
      delete :destroy, id: @nota_fiscal
    end

    assert_redirected_to nota_fiscais_path
  end
end
