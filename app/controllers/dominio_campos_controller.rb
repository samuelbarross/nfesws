class DominioCamposController < ApplicationController
  before_action :set_dominio_campo, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
  # GET /dominio_campos
  # GET /dominio_campos.json
  def index
    @search = DominioCampo.search(params[:q])
    if params[:q].nil?
      #  @nota_fiscais = NotaFiscal.order("dtEmissaoNfe").limit(10)
      @dominio_campos = DominioCampo.order("id")
     else
      @dominio_campos = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
  end


  # GET /dominio_campos/1
  # GET /dominio_campos/1.json
  def show
  end

  # GET /dominio_campos/new
  def new
    @dominio_campo = DominioCampo.new
  end

  # GET /dominio_campos/1/edit
  def edit
  end

  # POST /dominio_campos
  # POST /dominio_campos.json
  def create
    @dominio_campo = DominioCampo.new(dominio_campo_params)

    respond_to do |format|
      if @dominio_campo.save
        format.html { redirect_to @dominio_campo, notice: 'Dominio campo was successfully created.' }
        format.json { render action: 'show', status: :created, location: @dominio_campo }
      else
        format.html { render action: 'new' }
        format.json { render json: @dominio_campo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dominio_campos/1
  # PATCH/PUT /dominio_campos/1.json
  def update
    respond_to do |format|
      if @dominio_campo.update(dominio_campo_params)
        format.html { redirect_to @dominio_campo, notice: 'Dominio campo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @dominio_campo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dominio_campos/1
  # DELETE /dominio_campos/1.json
  def destroy
    @dominio_campo.destroy
    respond_to do |format|
      format.html { redirect_to dominio_campos_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dominio_campo
      @dominio_campo = DominioCampo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dominio_campo_params
      params.require(:dominio_campo).permit(:descricao, :dominio_id)
    end
end
