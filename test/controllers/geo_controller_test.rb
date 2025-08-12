require 'test_helper'

class GeoControllerTest < ActionController::TestCase
  setup do
    @user = users(:one)
    @location_data = { country: "ES", city: "Madrid", region: "Madrid", timezone: "Europe/Madrid" }
  end

  test "should get current location" do
    # Mock del concern
    @controller.stubs(:location_already_cached?).returns(true)
    @controller.stubs(:cached_location).returns(@location_data)
    
    get :current, format: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal @location_data, json_response['location']
    assert_equal 'ip_detection', json_response['source']
  end

  test "should redirect HTML requests to root" do
    get :current
    
    assert_redirected_to root_path
  end

  test "should handle location detection failure" do
    @controller.stubs(:location_already_cached?).returns(true)
    @controller.stubs(:cached_location).returns({})
    
    get :current, format: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "No se pudo detectar ubicación", json_response['message']
  end

  test "should update exact location for signed in user" do
    sign_in @user
    
    patch :update, params: {
      latitude: "40.4168",
      longitude: "-3.7038",
      zip: "28001",
      timezone: "Europe/Madrid"
    }, format: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal "Ubicación actualizada", json_response['message']
    
    @user.reload
    assert_equal "40.4168", @user.current_latitude
    assert_equal "-3.7038", @user.current_longitude
    assert_equal "28001", @user.current_zip
    assert_equal "Europe/Madrid", @user.current_timezone
  end

  test "should require authentication for update" do
    patch :update, params: {
      latitude: "40.4168",
      longitude: "-3.7038"
    }, format: :json
    
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Usuario debe estar loggeado", json_response['message']
  end

  test "should validate required coordinates" do
    sign_in @user
    
    patch :update, params: { latitude: "40.4168" }, format: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Coordenadas latitud y longitud son requeridas", json_response['message']
  end

  test "should validate coordinate format" do
    sign_in @user
    
    patch :update, params: {
      latitude: "invalid",
      longitude: "-3.7038"
    }, format: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Formato de coordenadas inválido", json_response['message']
  end

  test "should validate coordinate ranges" do
    sign_in @user
    
    patch :update, params: {
      latitude: "100.0", # Fuera de rango (-90 a 90)
      longitude: "-3.7038"
    }, format: :json
    
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_not json_response['success']
    assert_equal "Coordenadas fuera de rango válido", json_response['message']
  end

  test "should only update changed fields" do
    sign_in @user
    @user.update!(current_latitude: "40.4168", current_longitude: "-3.7038")
    
    patch :update, params: {
      latitude: "40.4168", # Misma latitud
      longitude: "-3.7038"  # Misma longitud
    }, format: :json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_equal "No hay cambios para actualizar", json_response['message']
  end
end
