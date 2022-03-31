class DominioValoresController < ApplicationController
  before_action :set_dominio_valor, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  # GET /dominio_valores
  # GET /dominio_valores.json
  def index
    @search = DominioValor.search(params[:q])
    if params[:q].nil?
      #  @nota_fiscais = NotaFiscal.order("dtEmissaoNfe").limit(10)
      @dominio_valores = DominioValor.order("id")
     else
      @dominio_valores = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
  end

  # GET /dominio_valores/1
  # GET /dominio_valores/1.json
  def show
  end

  # GET /dominio_valores/new
  def new
    @dominio_valor = DominioValor.new
  end

  # GET /dominio_valores/1/edit
  def edit
  end

  # POST /dominio_valores
  # POST /dominio_valores.json
  def create
    @dominio_valor = DominioValor.new(dominio_valor_params)

    respond_to do |format|
      if @dominio_valor.save
        format.html { redirect_to @dominio_valor, notice: 'Dominio valor was successfully created.' }
        format.json { render action: 'show', status: :created, location: @dominio_valor }
      else
        format.html { render action: 'new' }
        format.json { render json: @dominio_valor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dominio_valores/1
  # PATCH/PUT /dominio_valores/1.json
  def update
    respond_to do |format|
      if @dominio_valor.update(dominio_valor_params)
        format.html { redirect_to @dominio_valor, notice: 'Dominio valor was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @dominio_valor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dominio_valores/1
  # DELETE /dominio_valores/1.json
  def destroy
    @dominio_valor.destroy
    respond_to do |format|
      format.html { redirect_to dominio_valores_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dominio_valor
      @dominio_valor = DominioValor.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dominio_valor_params
      params.require(:dominio_valor).permit(:codigo, :descricao, :dominio_id)
    end
end
