class EmpresasController < ApplicationController
  before_action :set_empresa, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  respond_to :html

  def index
    @search = Empresa.search(params[:q])
    if params[:q].nil?
      @empresas = Empresa.order("id")
     else
      @empresas = @search.result
    end
    @search.build_condition if @search.conditions.empty?
    @search.build_sort if @search.sorts.empty?

    authorize @empresas
  end


  def show
    @usuario_empresas = User.where(id: UsuarioEmpresa.includes(:empresa).where(empresa_id: params[:id]).map{|f| "#{f.user_id}"})
    respond_with(@empresa)
  end

  def new
    @empresa = Empresa.new
    authorize @empresa
    respond_with(@empresa)
  end

  def edit
    authorize @empresa
    # @users = User.all.order(:email)
  end

  def create
    @empresa = Empresa.new(empresa_params)
    @empresa.save
    respond_with(@empresa)
  end

  def update
    @empresa.update(empresa_params)
    respond_with(@empresa)
  end

  def destroy
    @empresa.destroy
    respond_with(@empresa)
  end

  private
    def set_empresa
      @empresa = Empresa.find(params[:id])
    end

    def empresa_params
      params.require(:empresa).permit(:id, :cnpj, :nome, :path_certificado, :senha_certificado, :ult_nsu, :cod_uf, :max_nsu,
                usuario_empresas_attributes: [:id, :user_id, :empresa_id, :_destroy])
    end
end
