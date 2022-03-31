require 'test_helper'

class DominiosControllerTest < ActionController::TestCase
  setup do
    @dominio = dominios(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dominios)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dominio" do
    assert_difference('Dominio.count') do
      post :create, dominio: { descricao: @dominio.descricao }
    end

    assert_redirected_to dominio_path(assigns(:dominio))
  end

  test "should show dominio" do
    get :show, id: @dominio
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dominio
    assert_response :success
  end

  test "should update dominio" do
    patch :update, id: @dominio, dominio: { descricao: @dominio.descricao }
    assert_redirected_to dominio_path(assigns(:dominio))
  end

  test "should destroy dominio" do
    assert_difference('Dominio.count', -1) do
      delete :destroy, id: @dominio
    end

    assert_redirected_to dominios_path
  end
end
