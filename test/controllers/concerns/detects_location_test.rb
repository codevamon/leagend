require 'test_helper'

class DetectsLocationTest < ActionController::TestCase
  class TestController < ActionController::Base
    include DetectsLocation
    
    def index
      render plain: 'OK'
    end
  end
  
  tests TestController
  
  setup do
    @controller = TestController.new
    @request = ActionController::TestRequest.create(TestController)
    @response = ActionController::TestResponse.new
  end

  test "should detect location by IP" do
    # Mock de la respuesta de ipinfo.io
    mock_response = mock
    mock_response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    mock_response.stubs(:body).returns('{"country":"ES","city":"Madrid","region":"Madrid","timezone":"Europe/Madrid"}')
    
    Net::HTTP.stubs(:get_response).returns(mock_response)
    
    location = @controller.send(:detect_location_by_ip)
    
    assert_equal "ES", location[:country]
    assert_equal "Madrid", location[:city]
    assert_equal "Madrid", location[:region]
    assert_equal "Europe/Madrid", location[:timezone]
  end

  test "should handle IP detection errors gracefully" do
    Net::HTTP.stubs(:get_response).raises(StandardError.new("Network error"))
    
    location = @controller.send(:detect_location_by_ip)
    
    assert_nil location
  end

  test "should cache location in cookies and session" do
    location = { country: "ES", city: "Madrid" }
    
    @controller.send(:cache_location, location)
    
    assert_equal "ES", @controller.cookies[:location_country]
    assert_equal "Madrid", @controller.cookies[:location_city]
    assert @controller.session[:location_detected]
    assert_equal location, @controller.session[:location_data]
  end

  test "should check if location is already cached" do
    # Sin cache
    assert_not @controller.send(:location_already_cached?)
    
    # Con cookies
    @controller.cookies[:location_country] = "ES"
    assert @controller.send(:location_already_cached?)
    
    # Con sesión
    @controller.cookies.delete(:location_country)
    @controller.session[:location_detected] = true
    assert @controller.send(:location_already_cached?)
  end

  test "should get cached location" do
    @controller.cookies[:location_country] = "ES"
    @controller.cookies[:location_city] = "Madrid"
    
    location = @controller.send(:cached_location)
    
    assert_equal "ES", location[:country]
    assert_equal "Madrid", location[:city]
  end
end
