class NotaDuplicatasController < ApplicationController
  before_action :set_nota_duplicata, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  
  # GET /nota_duplicatas
  # GET /nota_duplicatas.json

  def index
    @search = NotaDuplicata.search(params[:q])
    if params[:q].nil?
       @nota_duplicatas = NotaDuplicata.order("dtVencimento").limit(10)
     else
      @nota_duplicatas = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?
  end

  # GET /nota_duplicatas/1
  # GET /nota_duplicatas/1.json
  def show
  end

  # GET /nota_duplicatas/new
  def new
    @nota_duplicata = NotaDuplicata.new
  end

  # GET /nota_duplicatas/1/edit
  def edit
  end

  # POST /nota_duplicatas
  # POST /nota_duplicatas.json
  def create
    @nota_duplicata = NotaDuplicata.new(nota_duplicata_params)

    respond_to do |format|
      if @nota_duplicata.save
        format.html { redirect_to @nota_duplicata, notice: 'Nota duplicata was successfully created.' }
        format.json { render action: 'show', status: :created, location: @nota_duplicata }
      else
        format.html { render action: 'new' }
        format.json { render json: @nota_duplicata.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /nota_duplicatas/1
  # PATCH/PUT /nota_duplicatas/1.json
  def update
    respond_to do |format|
      if @nota_duplicata.update(nota_duplicata_params)
        format.html { redirect_to @nota_duplicata, notice: 'Nota duplicata was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @nota_duplicata.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nota_duplicatas/1
  # DELETE /nota_duplicatas/1.json
  def destroy
    @nota_duplicata.destroy
    respond_to do |format|
      format.html { redirect_to nota_duplicatas_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nota_duplicata
      @nota_duplicata = NotaDuplicata.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def nota_duplicata_params
      params.require(:nota_duplicata).permit(:nrDuplicata, :dtVencimento, :valorDuplicata, :notaFiscal_id)
    end
end
