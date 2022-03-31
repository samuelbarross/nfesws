require 'test_helper'

class CronsControllerTest < ActionController::TestCase
  setup do
    @crom = crons(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:crons)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create crom" do
    assert_difference('Cron.count') do
      post :create, crom: { cnpj: @crom.cnpj, data: @crom.data, mensagem: @crom.mensagem, xml_retorno: @crom.xml_retorno }
    end

    assert_redirected_to crom_path(assigns(:crom))
  end

  test "should show crom" do
    get :show, id: @crom
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @crom
    assert_response :success
  end

  test "should update crom" do
    patch :update, id: @crom, crom: { cnpj: @crom.cnpj, data: @crom.data, mensagem: @crom.mensagem, xml_retorno: @crom.xml_retorno }
    assert_redirected_to crom_path(assigns(:crom))
  end

  test "should destroy crom" do
    assert_difference('Cron.count', -1) do
      delete :destroy, id: @crom
    end

    assert_redirected_to crons_path
  end
end
