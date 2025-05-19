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

    if mode == 'express'
      express_minutes = params[:express_minutes].to_i
      starts_at = Time.current + express_minutes.minutes - 20.minutes
    else
      starts_at = Time.zone.local(
        params["duel"]["starts_at(1i)"].to_i,
        params["duel"]["starts_at(2i)"].to_i,
        params["duel"]["starts_at(3i)"].to_i,
        params["duel"]["starts_at(4i)"].to_i,
        params["duel"]["starts_at(5i)"].to_i
      )
    end

    ends_at = starts_at + duration.minutes

    {
      duel_type: duel_type,
      mode: mode,
      starts_at: starts_at,
      ends_at: ends_at,
      duration: duration
    }
  end

  def self.create_team_and_callup(params, current_user)
    begin
      joinable = params[:joinable_type].constantize.find(params[:joinable_id])
      duel = Duel.find_by(id: params[:duel_id])

      team = joinable.teams.first || Team.create!(
        name: "Equipo #{joinable.name}",
        captain_id: current_user.id,
        joinable_id: joinable.id,
        joinable_type: joinable.class.name,
        temporary: true,
        expires_at: (Time.zone.parse(params[:starts_at]) rescue 24.hours.from_now),
        status: :pending
      )

      Result.new(success: true, data: { team: team })
    rescue => e
      Result.new(success: false, error: e.message)
    end
  end

  def self.send_callup(params, current_user)
    begin
      team = Team.find(params[:team_id])
      user = User.find(params[:user_id])
      duel = Duel.find_by(home_team: team)

      callup = Callup.find_or_initialize_by(user: user, teamable: team)
      callup.duel = duel if duel.present?
      callup.status = (current_user == user) ? :accepted : :pending
      callup.save!

      if current_user == user && duel.present?
        Lineup.find_or_create_by!(
          duel: duel,
          user: user,
          teamable: team
        )
      end

      if current_user != user
        NotificationService.notify_callup(callup, current_user)
      end

      Result.new(success: true, message: "Convocatoria enviada exitosamente")
    rescue => e
      Result.new(success: false, error: e.message)
    end
  end

  def self.send_callups_to_all(params, current_user)
    begin
      team = Team.find(params[:team_id])
      duel = Duel.find_by(home_team: team)
      user_ids = params[:user_ids]

      users = User.where(id: user_ids)

      users.each do |user|
        callup = Callup.find_or_initialize_by(user: user, teamable: team)
        callup.duel = duel if duel.present?
        callup.status = (current_user == user) ? :accepted : :pending
        callup.save!

        if duel.present? && current_user == user
          Lineup.find_or_create_by!(
            duel: duel,
            user: user,
            teamable: team
          )
        end

        if current_user != user
          NotificationService.notify_callup(callup, current_user)
        end
      end

      Result.new(success: true, message: "Convocatorias enviadas exitosamente")
    rescue => e
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