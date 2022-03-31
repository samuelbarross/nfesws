require 'test_helper'

class DominioCamposControllerTest < ActionController::TestCase
  setup do
    @dominio_campo = dominio_campos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dominio_campos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dominio_campo" do
    assert_difference('DominioCampo.count') do
      post :create, dominio_campo: { descricao: @dominio_campo.descricao, dominio_id: @dominio_campo.dominio_id }
    end

    assert_redirected_to dominio_campo_path(assigns(:dominio_campo))
  end

  test "should show dominio_campo" do
    get :show, id: @dominio_campo
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dominio_campo
    assert_response :success
  end

  test "should update dominio_campo" do
    patch :update, id: @dominio_campo, dominio_campo: { descricao: @dominio_campo.descricao, dominio_id: @dominio_campo.dominio_id }
    assert_redirected_to dominio_campo_path(assigns(:dominio_campo))
  end

  test "should destroy dominio_campo" do
    assert_difference('DominioCampo.count', -1) do
      delete :destroy, id: @dominio_campo
    end

    assert_redirected_to dominio_campos_path
  end
end
