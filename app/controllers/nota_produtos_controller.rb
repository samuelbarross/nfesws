class NotaProdutosController < ApplicationController
  before_action :set_nota_produto, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
  # GET /nota_produtos
  # GET /nota_produtos.json

  def index
    @search = NotaProduto.search(params[:q])
    if params[:q].nil?
       @nota_produtos = NotaProduto.order("nrItem").limit(10)
     else
      @nota_produtos = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
  end

  # GET /nota_produtos/1
  # GET /nota_produtos/1.json
  def show
  end

  # GET /nota_produtos/new
  def new
    @nota_produto = NotaProduto.new
  end

  # GET /nota_produtos/1/edit
  def edit
  end

  # POST /nota_produtos
  # POST /nota_produtos.json
  def create
    @nota_produto = NotaProduto.new(nota_produto_params)

    respond_to do |format|
      if @nota_produto.save
        format.html { redirect_to @nota_produto, notice: 'Nota produto was successfully created.' }
        format.json { render action: 'show', status: :created, location: @nota_produto }
      else
        format.html { render action: 'new' }
        format.json { render json: @nota_produto.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nota_produtos/1
  # PATCH/PUT /nota_produtos/1.json
  def update
    respond_to do |format|
      if @nota_produto.update(nota_produto_params)
        format.html { redirect_to @nota_produto, notice: 'Nota produto was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @nota_produto.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nota_produtos/1
  # DELETE /nota_produtos/1.json
  def destroy
    @nota_produto.destroy
    respond_to do |format|
      format.html { redirect_to nota_produtos_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nota_produto
      @nota_produto = NotaProduto.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def nota_produto_params
      params.require(:nota_produto).permit(:nrItem, :descricao, :qtdeComercial, :qtdeTributavel, :unidadeComercial, :unidadeTributavel, :valorUnitarioComercializacao, :float, :codProduto, :codNCM, :codExTIPI, :cfop, :outrasDespesasAcessorias, :valorDesconto, :valorTotalFrete, :valorSeg, :indicadorComposicaoValorTotalNfe, :codEANComercial, :codEANTributavel, :nrPedidoCompra, :itemPedidoCompra, :valorAproximadoTributos, :nrFCI, :origemMercadoria, :codTributacaoICMS, :valorBCICMSSTRetido, :valorICMSSTRet, :pisCST, :cofinsCST, :informacoesAdicionaisProduto, :notaFiscal_id)
    end
end
