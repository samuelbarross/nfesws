require 'test_helper'

class NotaProdutosControllerTest < ActionController::TestCase
  setup do
    @nota_produto = nota_produtos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:nota_produtos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create nota_produto" do
    assert_difference('NotaProduto.count') do
      post :create, nota_produto: { cfop: @nota_produto.cfop, codEANComercial: @nota_produto.codEANComercial, codEANTributavel: @nota_produto.codEANTributavel, codExTIPI: @nota_produto.codExTIPI, codNCM: @nota_produto.codNCM, codProduto: @nota_produto.codProduto, codTributacaoICMS: @nota_produto.codTributacaoICMS, cofinsCST: @nota_produto.cofinsCST, descricao: @nota_produto.descricao, float: @nota_produto.float, indicadorComposicaoValorTotalNfe: @nota_produto.indicadorComposicaoValorTotalNfe, informacoesAdicionaisProduto: @nota_produto.informacoesAdicionaisProduto, itemPedidoCompra: @nota_produto.itemPedidoCompra, notaFiscal_id: @nota_produto.notaFiscal_id, nrFCI: @nota_produto.nrFCI, nrItem: @nota_produto.nrItem, nrPedidoCompra: @nota_produto.nrPedidoCompra, origemMercadoria: @nota_produto.origemMercadoria, outrasDespesasAcessorias: @nota_produto.outrasDespesasAcessorias, pisCST: @nota_produto.pisCST, qtdeComercial: @nota_produto.qtdeComercial, qtdeTributavel: @nota_produto.qtdeTributavel, unidadeComercial: @nota_produto.unidadeComercial, unidadeTributavel: @nota_produto.unidadeTributavel, valorAproximadoTributos: @nota_produto.valorAproximadoTributos, valorBCICMSSTRetido: @nota_produto.valorBCICMSSTRetido, valorDesconto: @nota_produto.valorDesconto, valorICMSSTRet: @nota_produto.valorICMSSTRet, valorSeg: @nota_produto.valorSeg, valorTotalFrete: @nota_produto.valorTotalFrete, valorUnitarioComercializacao: @nota_produto.valorUnitarioComercializacao }
    end

    assert_redirected_to nota_produto_path(assigns(:nota_produto))
  end

  test "should show nota_produto" do
    get :show, id: @nota_produto
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @nota_produto
    assert_response :success
  end

  test "should update nota_produto" do
    patch :update, id: @nota_produto, nota_produto: { cfop: @nota_produto.cfop, codEANComercial: @nota_produto.codEANComercial, codEANTributavel: @nota_produto.codEANTributavel, codExTIPI: @nota_produto.codExTIPI, codNCM: @nota_produto.codNCM, codProduto: @nota_produto.codProduto, codTributacaoICMS: @nota_produto.codTributacaoICMS, cofinsCST: @nota_produto.cofinsCST, descricao: @nota_produto.descricao, float: @nota_produto.float, indicadorComposicaoValorTotalNfe: @nota_produto.indicadorComposicaoValorTotalNfe, informacoesAdicionaisProduto: @nota_produto.informacoesAdicionaisProduto, itemPedidoCompra: @nota_produto.itemPedidoCompra, notaFiscal_id: @nota_produto.notaFiscal_id, nrFCI: @nota_produto.nrFCI, nrItem: @nota_produto.nrItem, nrPedidoCompra: @nota_produto.nrPedidoCompra, origemMercadoria: @nota_produto.origemMercadoria, outrasDespesasAcessorias: @nota_produto.outrasDespesasAcessorias, pisCST: @nota_produto.pisCST, qtdeComercial: @nota_produto.qtdeComercial, qtdeTributavel: @nota_produto.qtdeTributavel, unidadeComercial: @nota_produto.unidadeComercial, unidadeTributavel: @nota_produto.unidadeTributavel, valorAproximadoTributos: @nota_produto.valorAproximadoTributos, valorBCICMSSTRetido: @nota_produto.valorBCICMSSTRetido, valorDesconto: @nota_produto.valorDesconto, valorICMSSTRet: @nota_produto.valorICMSSTRet, valorSeg: @nota_produto.valorSeg, valorTotalFrete: @nota_produto.valorTotalFrete, valorUnitarioComercializacao: @nota_produto.valorUnitarioComercializacao }
    assert_redirected_to nota_produto_path(assigns(:nota_produto))
  end

  test "should destroy nota_produto" do
    assert_difference('NotaProduto.count', -1) do
      delete :destroy, id: @nota_produto
    end

    assert_redirected_to nota_produtos_path
  end
end
