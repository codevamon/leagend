require "test_helper"

class ArenaTest < ActiveSupport::TestCase
  setup do
    @owner = owners(:one)
  end

  test "should geocode when address changes and no coordinates present" do
    arena = Arena.new(
      name: "Test Arena",
      address: "Calle 123",
      city: "Bogotá",
      country: "Colombia",
      owner: @owner
    )
    
    # Mock de Geocoder para simular respuesta
    Geocoder.stub :search, [double(latitude: 4.7110, longitude: -74.0721)] do
      arena.save!
    end
    
    assert_equal 4.7110, arena.latitude
    assert_equal(-74.0721, arena.longitude)
  end

  test "should not geocode when coordinates are already present" do
    arena = Arena.new(
      name: "Test Arena",
      address: "Calle 123",
      city: "Bogotá", 
      country: "Colombia",
      latitude: 5.0000,
      longitude: -75.0000,
      owner: @owner
    )
    
    # No debería llamar a geocode
    arena.expects(:geocode).never
    arena.save!
    
    assert_equal 5.0000, arena.latitude
    assert_equal(-75.0000, arena.longitude)
  end

  test "should geocode when address fields change" do
    arena = Arena.create!(
      name: "Test Arena",
      address: "Calle 123",
      city: "Bogotá",
      country: "Colombia",
      owner: @owner
    )
    
    # Mock de Geocoder para simular respuesta
    Geocoder.stub :search, [double(latitude: 6.2442, longitude: -75.5812)] do
      arena.update!(address: "Calle 456")
    end
    
    assert_equal 6.2442, arena.latitude
    assert_equal(-75.5812, arena.longitude)
  end

  test "should not geocode when only other fields change" do
    arena = Arena.create!(
      name: "Test Arena",
      address: "Calle 123",
      city: "Bogotá",
      country: "Colombia",
      owner: @owner
    )
    
    # No debería llamar a geocode si solo cambia el nombre
    arena.expects(:geocode).never
    arena.update!(name: "New Arena Name")
  end

  test "full_address concatenates address components correctly" do
    arena = Arena.new(
      address: "Calle 123",
      city: "Bogotá",
      country: "Colombia"
    )
    
    assert_equal "Calle 123, Bogotá, Colombia", arena.full_address
  end

  test "full_address handles missing components gracefully" do
    arena = Arena.new(
      address: "Calle 123",
      city: nil,
      country: "Colombia"
    )
    
    assert_equal "Calle 123, Colombia", arena.full_address
  end
end
