class DominiosController < ApplicationController
  before_action :set_dominio, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
  # GET /dominios
  # GET /dominios.json
  def index
    @search = Dominio.search(params[:q])
    if params[:q].nil?
      #  @nota_fiscais = NotaFiscal.order("dtEmissaoNfe").limit(10)
      @dominios = Dominio.order("id")
     else
      @dominios = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
    authorize @dominios
  end

  # GET /dominios/1
  # GET /dominios/1.json
  def show
    @dominio_valores = DominioValor.where("dominio_id = " + params[:id].to_s)
    @dominio_campos = DominioCampo.where("dominio_id = " + params[:id].to_s)
  end

  # GET /dominios/new
  def new
    @dominio = Dominio.new
    authorize @dominio
  end

  # GET /dominios/1/edit
  def edit
    authorize @dominio
  end

  # POST /dominios
  # POST /dominios.json
  def create
    @dominio = Dominio.new(dominio_params)
    respond_to do |format|
      if @dominio.save
        format.html { redirect_to @dominio, notice: 'Dominio was successfully created.' }
        format.json { render action: 'show', status: :created, location: @dominio }
      else
        format.html { render action: 'new' }
        format.json { render json: @dominio.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dominios/1
  # PATCH/PUT /dominios/1.json
  def update
    respond_to do |format|
      if @dominio.update(dominio_params)
        format.html { redirect_to @dominio, notice: 'Dominio was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @dominio.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dominios/1
  # DELETE /dominios/1.json
  def destroy
    authorize @dominio
    respond_to do |format|
      format.html { redirect_to dominios_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dominio
      @dominio = Dominio.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dominio_params
      params.require(:dominio).permit(:id, :descricao,
        dominio_valores_attributes: [:id, :codigo, :descricao, :_destroy],
        dominio_campos_attributes: [:id, :descricao, :_destroy])
    end
end
