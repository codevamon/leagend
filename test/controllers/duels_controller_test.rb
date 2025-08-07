require "test_helper"

class DuelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @duel = duels(:one)
    @team = teams(:one)
    sign_in @user
  end

  test "should get available_players" do
    # Crear un equipo temporal para el duelo
    @duel.update!(home_team: @team)
    @team.update!(temporary: true, captain: @user)
    
    get available_players_duel_url(@duel)
    assert_response :success
    assert_select "h2", "Convocar Jugadores"
  end

  test "should redirect if no temporary team" do
    get available_players_duel_url(@duel)
    assert_redirected_to manage_duel_path(@duel)
    assert_equal "No hay equipo temporal asignado.", flash[:alert]
  end

  test "should show all users in available_players" do
    # Crear un equipo temporal para el duelo
    @duel.update!(home_team: @team)
    @team.update!(temporary: true, captain: @user)
    
    # Crear algunos usuarios adicionales
    user2 = users(:two)
    user3 = users(:three)
    
    get available_players_duel_url(@duel)
    assert_response :success
    
    # Verificar que se muestran todos los usuarios (excepto el actual)
    assert_select ".user-card", User.count - 1
  end

  test "should callup player successfully" do
    # Crear un equipo temporal para el duelo
    @duel.update!(home_team: @team)
    @team.update!(temporary: true, captain: @user)
    
    user2 = users(:two)
    
    assert_difference('Callup.count') do
      post callup_player_duel_url(@duel), params: { user_id: user2.id }
    end
    
    assert_response :success
    callup = Callup.last
    assert_equal user2, callup.user
    assert_equal @team, callup.teamable
    assert_equal @duel, callup.duel
    assert_equal "pending", callup.status
  end

  test "should self callup captain successfully" do
    # Crear un equipo temporal para el duelo
    @duel.update!(home_team: @team)
    @team.update!(temporary: true, captain: @user)
    
    assert_difference('Callup.count') do
      post self_callup_captain_duel_url(@duel)
    end
    
    assert_response :success
    callup = Callup.last
    assert_equal @user, callup.user
    assert_equal @team, callup.teamable
    assert_equal @duel, callup.duel
    assert_equal "accepted", callup.status
  end

  test "should not allow non-captain to self callup" do
    # Crear un equipo temporal para el duelo con otro capitán
    other_user = users(:two)
    @duel.update!(home_team: @team)
    @team.update!(temporary: true, captain: other_user)
    
    assert_no_difference('Callup.count') do
      post self_callup_captain_duel_url(@duel)
    end
    
    assert_response :success
  end

  test "should postpone duel successfully" do
    # Configurar duelo para que pueda ser postergado
    @duel.update!(home_team: @team, status: :pending, starts_at: 2.hours.from_now, ends_at: 3.hours.from_now)
    @team.update!(temporary: true, captain: @user)
    
    original_starts_at = @duel.starts_at
    original_ends_at = @duel.ends_at
    
    patch postpone_duel_url(@duel), params: { hours: 4 }
    
    assert_response :success
    @duel.reload
    
    # Verificar que las fechas se actualizaron correctamente
    assert_equal original_starts_at + 4.hours, @duel.starts_at
    assert_equal original_ends_at + 4.hours, @duel.ends_at
    assert_equal "postponed", @duel.status
  end

  test "should not postpone duel if not allowed" do
    # Configurar duelo que no puede ser postergado (ya iniciado)
    @duel.update!(home_team: @team, status: :ongoing)
    @team.update!(temporary: true, captain: @user)
    
    patch postpone_duel_url(@duel), params: { hours: 4 }
    
    assert_response :success
    @duel.reload
    
    # Verificar que no se cambió el status
    assert_equal "ongoing", @duel.status
  end

  test "should reject invalid hours for postponement" do
    # Configurar duelo para que pueda ser postergado
    @duel.update!(home_team: @team, status: :pending, starts_at: 2.hours.from_now, ends_at: 3.hours.from_now)
    @team.update!(temporary: true, captain: @user)
    
    patch postpone_duel_url(@duel), params: { hours: 3 } # 3 no está en la lista válida
    
    assert_response :success
    @duel.reload
    
    # Verificar que no se cambió el status
    assert_equal "pending", @duel.status
  end
end
