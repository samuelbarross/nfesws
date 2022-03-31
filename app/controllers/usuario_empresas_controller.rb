class UsuarioEmpresasController < ApplicationController
  before_action :set_usuario_empresa, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @usuario_empresas = UsuarioEmpresa.all
    respond_with(@usuario_empresas)
  end

  def show
    respond_with(@usuario_empresa)
  end

  def new
    @usuario_empresa = UsuarioEmpresa.new
    respond_with(@usuario_empresa)
  end

  def edit
  end

  def create
    @usuario_empresa = UsuarioEmpresa.new(usuario_empresa_params)
    @usuario_empresa.save
    respond_with(@usuario_empresa)
  end

  def update
    @usuario_empresa.update(usuario_empresa_params)
    respond_with(@usuario_empresa)
  end

  def destroy
    @usuario_empresa.destroy
    respond_with(@usuario_empresa)
  end

  private
    def set_usuario_empresa
      @usuario_empresa = UsuarioEmpresa.find(params[:id])
    end

    def usuario_empresa_params
      params.require(:usuario_empresa).permit(:user_id, :empresa_id)
    end
end
