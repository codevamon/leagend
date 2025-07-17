require "test_helper"

class DuelTest < ActiveSupport::TestCase
  setup do
    @captain = users(:captain)
    @arena = arenas(:main)
    @home_team = teams(:home)
    @away_team = teams(:away)
  end

  test "crear duelo válido" do
    duel = Duel.new(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    assert duel.valid?
  end

  test "duelo requiere equipo local" do
    duel = Duel.new(
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours
    )
    assert_not duel.valid?
    assert_includes duel.errors[:home_team], "must exist"
  end

  test "duelo no puede terminar antes de empezar" do
    duel = Duel.new(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now - 1.hour
    )
    assert_not duel.valid?
    assert_includes duel.errors[:ends_at], "debe ser posterior a la hora de inicio"
  end

  test "duelo puede ser desafiado cuando está abierto" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena,
      status: :open
    )
    assert duel.can_be_challenged?
  end

  test "duelo no puede ser desafiado sin arena" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      status: :open
    )
    assert_not duel.can_be_challenged?
  end

  test "duelo puede iniciarse con jugadores suficientes" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    
    # Agregar jugadores necesarios
    5.times do |i|
      user = User.create!(
        email: "player#{i}@test.com",
        password: "password",
        firstname: "Player#{i}",
        lastname: "Test"
      )
      duel.lineups.create!(user: user, teamable: @home_team)
    end

    assert duel.has_minimum_players?
    assert duel.can_start?
  end

  test "duelo necesita atención cuando hay convocatorias pendientes" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.hour.from_now,
      ends_at: 1.hour.from_now + 2.hours,
      arena: @arena
    )

    # Crear convocatoria pendiente
    user = User.create!(
      email: "pending@test.com",
      password: "password",
      firstname: "Pending",
      lastname: "User"
    )
    duel.callups.create!(user: user, teamable: @home_team, status: :pending)

    assert duel.needs_attention?
  end

  test "duelo puede ser postergado antes de iniciar" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    assert duel.can_be_postponed?
  end

  test "duelo no puede ser postergado después de iniciar" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.ago,
      ends_at: 1.day.ago + 2.hours,
      arena: @arena
    )
    assert_not duel.can_be_postponed?
  end

  test "duelo puede ser cancelado antes de iniciar" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    assert duel.can_be_cancelled?
  end

  test "duelo no puede ser cancelado después de finalizar" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.ago,
      ends_at: 1.day.ago + 2.hours,
      arena: @arena,
      status: :finished
    )
    assert_not duel.can_be_cancelled?
  end

  test "duelo puede randomizar equipos cuando está pendiente" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    assert duel.can_randomize_teams?
  end

  test "duelo no puede randomizar equipos cuando está lleno" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )
    
    # Llenar el equipo
    5.times do |i|
      user = User.create!(
        email: "player#{i}@test.com",
        password: "password",
        firstname: "Player#{i}",
        lastname: "Test"
      )
      duel.lineups.create!(user: user, teamable: @home_team)
    end

    assert_not duel.can_randomize_teams?
  end

  test "registrar gol en duelo en curso" do
    duel = Duel.create!(
      home_team: @home_team,
      away_team: @away_team,
      duel_type: :friendly,
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now,
      arena: @arena,
      status: :ongoing
    )

    # Agregar jugadores
    player = User.create!(
      email: "scorer@test.com",
      password: "password",
      firstname: "Scorer",
      lastname: "Player"
    )
    duel.lineups.create!(user: player, teamable: @home_team)

    # Registrar gol
    assert_difference "duel.duel_goals.count" do
      duel.duel_goals.create!(
        user: player,
        team: @home_team,
        minute: 15
      )
    end

    assert_equal 1, duel.goals_by_team(@home_team)
    assert_equal 0, duel.goals_by_team(@away_team)
  end

  test "no se pueden registrar goles en duelo no iniciado" do
    duel = Duel.create!(
      home_team: @home_team,
      away_team: @away_team,
      duel_type: :friendly,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      arena: @arena,
      status: :pending
    )

    player = User.create!(
      email: "scorer@test.com",
      password: "password",
      firstname: "Scorer",
      lastname: "Player"
    )
    duel.lineups.create!(user: player, teamable: @home_team)

    assert_raises(ActiveRecord::RecordInvalid) do
      duel.duel_goals.create!(
        user: player,
        team: @home_team,
        minute: 15
      )
    end
  end

  test "finalizar duelo actualiza estadísticas" do
    duel = Duel.create!(
      home_team: @home_team,
      away_team: @away_team,
      duel_type: :friendly,
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now,
      arena: @arena,
      status: :ongoing
    )

    # Agregar jugadores y goles
    home_player = User.create!(
      email: "home_scorer@test.com",
      password: "password",
      firstname: "Home",
      lastname: "Scorer"
    )
    away_player = User.create!(
      email: "away_scorer@test.com",
      password: "password",
      firstname: "Away",
      lastname: "Scorer"
    )

    duel.lineups.create!(user: home_player, teamable: @home_team)
    duel.lineups.create!(user: away_player, teamable: @away_team)

    duel.duel_goals.create!(user: home_player, team: @home_team, minute: 15)
    duel.duel_goals.create!(user: home_player, team: @home_team, minute: 30)
    duel.duel_goals.create!(user: away_player, team: @away_team, minute: 45)

    # Finalizar duelo
    duel.update!(status: :finished)
    duel.create_result!(
      home_score: 2,
      away_score: 1,
      man_of_the_match: home_player
    )

    assert_equal :finished, duel.status
    assert_equal 2, duel.result.home_score
    assert_equal 1, duel.result.away_score
    assert_equal home_player, duel.man_of_the_match
  end

  test "notificaciones al cambiar estado del duelo" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )

    assert_difference "Notification.count" do
      duel.update!(status: :open)
    end

    assert_difference "Notification.count" do
      duel.update!(status: :ongoing)
    end

    assert_difference "Notification.count" do
      duel.update!(status: :finished)
    end
  end

  test "verificar disponibilidad de arena" do
    # Crear duelo que ocupa la arena
    Duel.create!(
      home_team: @home_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )

    # Intentar crear otro duelo en el mismo horario
    duel = Duel.new(
      home_team: @away_team,
      duel_type: :friendly,
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )

    assert_not duel.valid?
    assert_includes duel.errors[:arena], "no está disponible en ese horario"
  end

  test "verificar límites de jugadores según tipo de duelo" do
    duel = Duel.create!(
      home_team: @home_team,
      duel_type: :friendly, # 5 jugadores
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now + 2.hours,
      arena: @arena
    )

    # Agregar más jugadores de los permitidos
    6.times do |i|
      user = User.create!(
        email: "player#{i}@test.com",
        password: "password",
        firstname: "Player#{i}",
        lastname: "Test"
      )
      duel.lineups.create!(user: user, teamable: @home_team)
    end

    assert_not duel.valid?
    assert_includes duel.errors[:base], "Los equipos exceden el número máximo de jugadores"
  end
end
