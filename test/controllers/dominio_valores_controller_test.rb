require 'test_helper'

class DominioValoresControllerTest < ActionController::TestCase
  setup do
    @dominio_valor = dominio_valores(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dominio_valores)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dominio_valor" do
    assert_difference('DominioValor.count') do
      post :create, dominio_valor: { codigo: @dominio_valor.codigo, descricao: @dominio_valor.descricao, dominio_id: @dominio_valor.dominio_id }
    end

    assert_redirected_to dominio_valor_path(assigns(:dominio_valor))
  end

  test "should show dominio_valor" do
    get :show, id: @dominio_valor
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dominio_valor
    assert_response :success
  end

  test "should update dominio_valor" do
    patch :update, id: @dominio_valor, dominio_valor: { codigo: @dominio_valor.codigo, descricao: @dominio_valor.descricao, dominio_id: @dominio_valor.dominio_id }
    assert_redirected_to dominio_valor_path(assigns(:dominio_valor))
  end

  test "should destroy dominio_valor" do
    assert_difference('DominioValor.count', -1) do
      delete :destroy, id: @dominio_valor
    end

    assert_redirected_to dominio_valores_path
  end
end
