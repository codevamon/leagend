class DuelService
  class Result
    attr_reader :success, :error, :data

    def initialize(success:, error: nil, data: nil)
      @success = success
      @error = error
      @data = data
    end

    def success?
      @success
    end
  end

  def self.fetch_user_duels(user)
    joinables = user.memberships.approved.map(&:joinable)
    team_ids = joinables.flat_map(&:teams).map(&:id)
    
    Duel.where("home_team_id IN (:ids) OR away_team_id IN (:ids)", ids: team_ids)
  end

  def self.prepare_duel_data(params)
    duel_type = params[:duel_type]
    mode = params[:mode]
    duration = params[:duration].to_i

    Rails.logger.info "Preparando datos del duelo con parámetros: #{params.inspect}"

    if mode == 'express'
      express_minutes = params[:express_minutes].to_i
      starts_at = Time.current + express_minutes.minutes
    else
      # Manejar fecha y hora programada
      date = params[:date]
      time = params[:time]
      
      if date.present? && time.present?
        starts_at = Time.zone.parse("#{date} #{time}")
      else
        # Fallback a mañana a las 19:00
        starts_at = Time.current.tomorrow.change(hour: 19, min: 0, sec: 0)
      end
    end

    ends_at = starts_at + duration.minutes

    result = {
      "duel_type" => duel_type,
      "mode" => mode,
      "starts_at" => starts_at,
      "ends_at" => ends_at,
      "duration" => duration
    }

    Rails.logger.info "Datos del duelo preparados: #{result.inspect}"
    result
  end

  def self.create_team_and_callup(params, current_user)
    begin
      joinable = params[:joinable_type].constantize.find(params[:joinable_id])
      duel = Duel.find_by(id: params[:duel_id])

      # Parsear la fecha de inicio si está disponible
      starts_at = if params[:starts_at]
        if params[:starts_at].is_a?(String)
          Time.zone.parse(params[:starts_at])
        elsif params[:starts_at].is_a?(ActiveSupport::TimeWithZone) || params[:starts_at].is_a?(Time) || params[:starts_at].is_a?(DateTime)
          params[:starts_at]
        else
          Time.zone.parse(params[:starts_at].to_s)
        end
      else
        24.hours.from_now
      end
      
      team = joinable.teams.first || Team.create!(
        name: "Equipo #{joinable.name}",
        captain_id: current_user.id,
        joinable_id: joinable.id,
        joinable_type: joinable.class.name,
        temporary: true,
        expires_at: starts_at,
        status: :pending
      )

      Result.new(success: true, data: { team: team })
    rescue => e
      Result.new(success: false, error: e.message)
    end
  end

  def self.send_callup(params, current_user)
    # Permite recibir los parámetros tanto directos como anidados
    user_id = params[:user_id] || params.dig(:callup, :user_id)
    team_id = params[:team_id] || params.dig(:callup, :team_id)

    team = Team.find(team_id)
    user = User.find(user_id)
    duel = Duel.find_by(home_team: team)

    autoconvocado = (current_user == user)
    
    # Buscar callup existente o crear uno nuevo
    callup = Callup.find_or_initialize_by(user: user, teamable: team)
    
    # Solo actualizar si no existe o si es una autoconvocatoria
    if callup.new_record? || (autoconvocado && callup.pending?)
      callup.assign_attributes(
        duel: duel,
        status: autoconvocado ? :accepted : :pending
      )
      callup.save!
      
      # Crear lineup automáticamente para autoconvocatorias
      if autoconvocado && duel.present?
        Lineup.find_or_create_by!(duel: duel, user: user, teamable: team)
      end
      
      # Crear notificación solo si no es autoconvocatoria
      unless autoconvocado
        NotificationService.notify_callup(callup, current_user)
      end
      
      message = autoconvocado ? "Te has autoconvocado exitosamente" : "Convocatoria enviada exitosamente"
    else
      message = autoconvocado ? "Ya estás autoconvocado" : "Convocatoria ya enviada"
    end

    Result.new(success: true, message: message, data: { callup: callup, autoconvocado: autoconvocado })
  rescue => e
    Rails.logger.error "Error en send_callup: #{e.message}"
    Result.new(success: false, error: e.message)
  end

  def self.send_callups_to_all(params, current_user)
    begin
      team = Team.find(params[:team_id])
      user_ids = params[:user_ids]
      duel = Duel.find_by(home_team: team)
      users = User.where(id: user_ids)

      users.each do |user|
        callup = Callup.find_or_initialize_by(user: user, teamable: team)
        callup.assign_attributes(
          duel: duel,
          status: (current_user == user) ? :accepted : :pending
        )
        callup.save!

        if current_user == user && duel.present?
          Lineup.find_or_create_by!(duel: duel, user: user, teamable: team)
        end

        NotificationService.notify_callup(callup, current_user) if current_user != user
      end

      Result.new(success: true, message: "Convocatorias enviadas exitosamente")
    rescue => e
      Rails.logger.error "Error en DuelService.send_callups_to_all: #{e.message}"
      Result.new(success: false, error: e.message)
    end
  end

  def self.add_goal(duel, team_id, user_id)
    begin
      user = User.find(user_id)
      team = Team.find(team_id)

      Goal.create!(
        duel: duel,
        user: user,
        team: team,
        minute: Time.current - duel.starts_at
      )

      Result.new(success: true)
    rescue => e
      Result.new(success: false, error: e.message)
    end
  end

  def self.randomize_teams(duel)
    begin
      duel_type = duel.duel_type
      used_ids = duel.lineups.pluck(:user_id)
      pool = User.where.not(id: used_ids).limit(duel_type * 2)

      return Result.new(success: false, error: "No hay suficientes jugadores disponibles") if pool.count < duel_type * 2

      home_team = duel.home_team
      away_team = duel.away_team || Team.create!(
        name: "Reto #{duel_type}v#{duel_type}",
        captain_id: duel.home_team.captain_id
      )

      duel.update!(away_team: away_team)

      players = pool.shuffle
      home_players = players.shift(duel_type)
      away_players = players.shift(duel_type)

      (home_players + away_players).each do |user|
        team = home_players.include?(user) ? home_team : away_team
        Lineup.find_or_create_by!(duel: duel, user: user, teamable: team)
      end

      duel.update!(temporary: false)
      Result.new(success: true)
    rescue => e
      Result.new(success: false, error: e.message)
    end
  end
end 