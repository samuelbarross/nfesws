require 'test_helper'

class NotaDuplicatasControllerTest < ActionController::TestCase
  setup do
    @nota_duplicata = nota_duplicatas(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:nota_duplicatas)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create nota_duplicata" do
    assert_difference('NotaDuplicata.count') do
      post :create, nota_duplicata: { dtVencimento: @nota_duplicata.dtVencimento, notaFiscal_id: @nota_duplicata.notaFiscal_id, nrDuplicata: @nota_duplicata.nrDuplicata, valorDuplicata: @nota_duplicata.valorDuplicata }
    end

    assert_redirected_to nota_duplicata_path(assigns(:nota_duplicata))
  end

  test "should show nota_duplicata" do
    get :show, id: @nota_duplicata
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @nota_duplicata
    assert_response :success
  end

  test "should update nota_duplicata" do
    patch :update, id: @nota_duplicata, nota_duplicata: { dtVencimento: @nota_duplicata.dtVencimento, notaFiscal_id: @nota_duplicata.notaFiscal_id, nrDuplicata: @nota_duplicata.nrDuplicata, valorDuplicata: @nota_duplicata.valorDuplicata }
    assert_redirected_to nota_duplicata_path(assigns(:nota_duplicata))
  end

  test "should destroy nota_duplicata" do
    assert_difference('NotaDuplicata.count', -1) do
      delete :destroy, id: @nota_duplicata
    end

    assert_redirected_to nota_duplicatas_path
  end
end
