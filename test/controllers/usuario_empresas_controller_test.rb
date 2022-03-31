require 'test_helper'

class UsuarioEmpresasControllerTest < ActionController::TestCase
  setup do
    @usuario_empresa = usuario_empresas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:usuario_empresas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create usuario_empresa" do
    assert_difference('UsuarioEmpresa.count') do
      post :create, usuario_empresa: { empresa_id: @usuario_empresa.empresa_id, user_id: @usuario_empresa.user_id }
    end

    assert_redirected_to usuario_empresa_path(assigns(:usuario_empresa))
  end

  test "should show usuario_empresa" do
    get :show, id: @usuario_empresa
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @usuario_empresa
    assert_response :success
  end

  test "should update usuario_empresa" do
    patch :update, id: @usuario_empresa, usuario_empresa: { empresa_id: @usuario_empresa.empresa_id, user_id: @usuario_empresa.user_id }
    assert_redirected_to usuario_empresa_path(assigns(:usuario_empresa))
  end

  test "should destroy usuario_empresa" do
    assert_difference('UsuarioEmpresa.count', -1) do
      delete :destroy, id: @usuario_empresa
    end

    assert_redirected_to usuario_empresas_path
  end
end
