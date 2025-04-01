class DuelsController < ApplicationController
  before_action :set_teams, only: [:new, :create]

  # 🔹 Clásicos
  def new
    @duel = Duel.new
  end

  def create
    @duel = Duel.new(duel_params)
    if @duel.save
      RefereeAssigner.assign_to_duel(@duel)
      redirect_to @duel, notice: 'Duelo creado exitosamente.'
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :new
    end
  end

  def show
    @duel = Duel.includes(results: [:referee, :best_player]).find(params[:id])
    @home_team = @duel.home_team
    @away_team = @duel.away_team
    @home_team_users = @duel.callups.where(teamable: @home_team).map(&:user)
    @away_team_users = @duel.callups.where(teamable: @away_team).map(&:user)
    @challenger_duel = Duel
    .where(
      home_team_id: Team.where(captain_id: current_user.id).pluck(:id),
      away_team_id: nil
    )
    .where.not(arena_id: nil)
    .where(temporary: true)
    .order(created_at: :desc)
    .first
  end

  def my_duels
    joinables = current_user.memberships.approved.map(&:joinable)
  
    team_ids = joinables.flat_map(&:teams).map(&:id)
  
    @duels = Duel.where("home_team_id IN (:ids) OR away_team_id IN (:ids)", ids: team_ids)
                 .order(starts_at: :desc)
  end
  

  # 🔹 Flujo personalizado paso a paso
  def when
    @duel = Duel.new
  end

  def select_team

    duel_type = params[:duel_type]
    mode = params[:mode]
    duration = params[:duration].to_i
  
    if mode == 'express'
      express_minutes = params[:express_minutes].to_i
      starts_at = Time.current + express_minutes.minutes - 20.minutes # 20 min antes para cambiarse
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
  
    session[:duel_data] = {
      duel_type: duel_type,
      mode: mode,
      starts_at: starts_at,
      ends_at: ends_at,
      duration: duration
    }

    @memberships = current_user.memberships.includes(:joinable)
    @team_options = @memberships.select do |m|
      joinable = m.joinable
      joinable.is_a?(Clan) || (joinable.is_a?(Club) && (m.admin? || m.king?))
    end
  end

  def callup_players
    @duel_type = params[:duel_type]
    @starts_at = params[:starts_at]
    @ends_at = params[:ends_at]
  
    @team = Team.find(params[:team_id]) if params[:team_id].present?
  
    if @team
      @club_or_clan = @team.joinable
      @members = @club_or_clan.memberships.approved.includes(:user)
      @users = @members.map(&:user)
      @callups = Callup.where(teamable: @team)
    else
      redirect_to select_team_duels_path, alert: "No se pudo encontrar equipo"
    end
  end
  
  def create_team_and_callup
    
    joinable = params[:joinable_type].constantize.find(params[:joinable_id])
    duel = Duel.find_by(id: params[:duel_id])

    team = joinable.teams.first || Team.create!(
      name: "Equipo #{joinable.name}",
      captain_id: current_user.id,
      joinable_id: joinable.id,
      joinable_type: joinable.class.name
    )

    redirect_to callup_players_duels_path(
      team_id: team.id,
      duel_type: params[:duel_type],
      starts_at: params[:starts_at],
      ends_at: params[:ends_at]
    )
    # joinable = params[:joinable_type].constantize.find(params[:joinable_id])
    # if params[:duel_id].present?
    #   duel = Duel.find(params[:duel_id])
    # else
    #   duel = nil
    # end
  
    # existing_team = joinable.teams.first
  
    # if existing_team
    #   team = existing_team
    # else
    #   team = Team.create!(
    #     name: "Equipo #{joinable.name}",
    #     captain_id: current_user.id,
    #     joinable_id: joinable.id,
    #     joinable_type: joinable.class.name
    #   )
    # end
  
    # if duel
    #   redirect_to callup_players_duels_path(team_id: team.id, duel_id: duel.id)
    # else
    #   redirect_to callup_players_duels_path(team_id: team.id)
    # end
  end
  
  def send_callup
    @team = Team.find(params[:team_id])
    @user = User.find(params[:user_id])
    @duel = Duel.find_by(home_team: @team) # puede ser nil (aún no creado)
  
    callup = Callup.find_or_initialize_by(user: @user, teamable: @team)
    callup.duel = @duel if @duel.present?
    callup.status = (current_user == @user) ? :accepted : :pending
    callup.save!
  
    # Solo crear notificación si no es autoconvocatoria
    if current_user != @user
      unless Notification.exists?(recipient: @user, notifiable: callup, category: :callup)
        Notification.create!(
          recipient: @user,
          sender: current_user,
          message: "Fuiste convocado a un duelo.",
          category: :callup,
          notifiable: callup
        )
      end
    end
  
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end
  
  
  
  def send_callups_to_all
    team = Team.find(params[:team_id])
    user_ids = params[:user_ids] # array de UUIDs de users
  
    users = User.where(id: user_ids)
  
    users.each do |user|
      Callup.find_or_create_by!(
        user: user,
        teamable: team
      ) do |callup|
        callup.status = :pending
      end
    end
  
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def select_arena
    @team = Team.find(params[:team_id])
    data = session[:duel_data]
    
    @starts_at = Time.parse(data["starts_at"].to_s)
    @ends_at = Time.parse(data["ends_at"].to_s)
    @arenas = Arena.all.select { |a| a.available_between?(@duel.starts_at, @duel.ends_at) }
  end

  def open_duels
    @duels = Duel.where(status: :pending, private: false, opponent_id: nil)
  end

  def select_type
    @duel = Duel.find(params[:duel_id])
  end

  def confirm
    @duel = Duel.new(duel_params)
    RefereeAssigner.assign_to_duel(@duel) if params[:assign_referee] == '1'

    if @duel.save
      redirect_to @duel, notice: "Duelo creado con éxito."
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :select_type
    end
  end

  def responsibility
    @team = Team.find(params[:team_id])
    # Solo muestra la vista con el mensaje de responsabilidad.
  end

  def finalize_creation
    # Si no aceptó la responsabilidad, lo regresamos
    unless params[:accept_responsibility] == '1'
      redirect_to responsibility_duels_path(team_id: params[:team_id]),
                  alert: "Debes aceptar la responsabilidad antes de continuar."
      return
    end
  
    team = Team.find(params[:team_id])
    data = session[:duel_data]
  
    duel = Duel.create!(
      home_team: team,
      duel_type: data["duel_type"],
      starts_at: Time.parse(data["starts_at"].to_s),
      ends_at: Time.parse(data["ends_at"].to_s),
      duration: data["duration"].to_i,
      temporary: true,
      expires_at: Time.parse(data["starts_at"].to_s) + 24.hours,
      responsibility: true  # Marcamos que el creador aceptó la responsabilidad
    )
  
    # Vincular los callups existentes al Duel recién creado
    callups = Callup.where(teamable: team, duel_id: nil)
    callups.each { |c| c.update!(duel_id: duel.id) }
  
    # Crear un lineup para el creador si ya se había autoconvocado
    callup = callups.find { |c| c.user_id == current_user.id && c.accepted? }
    if callup
      Lineup.create!(duel: duel, user: current_user, teamable: team)
    end
  
    redirect_to duel_path(duel), notice: "Duelo creado con éxito."
  end
  
  
  
  def accept_opponent
    duel = Duel.find(params[:duel_id])
  
    # Crear el equipo del contrincante
    joinable = current_user.memberships.approved.first&.joinable
    team = joinable.teams.first || Team.create!(
      name: "Equipo #{joinable.name}",
      captain_id: current_user.id,
      joinable: joinable
    )
  
    duel.update!(
      away_team: team,
      temporary: false
    )
  
    redirect_to duel, notice: "Ahora participas en este duelo como visitante."
  end
  

  # 🔹 Funciones complementarias
  def start
    @duel = Duel.find(params[:id])
    @duel.update(status: 'started', managed_by_leaders: @duel.referee.nil?)
  end

  def add_goal
    duel = Duel.find(params[:id])
    user = User.find(params[:user_id])
    team = Team.find(params[:team_id])
    minute = params[:minute]

    GoalRegistrar.new(duel, user, team, minute).register_goal
    redirect_to duel, notice: 'Gol registrado exitosamente.'
  end

  private

    def set_teams
      @teams = Team.all
    end

    def duel_params
      params.require(:duel).permit(
        :home_team_id, :away_team_id,
        :referee_id, :best_player_id,
        :arena_id, :starts_at, :ends_at,
        :address, :neighborhood, :city, :country,
        :latitude, :longitude,
        :price, :budget, :budget_place, :budget_equipment, :referee_price,
        :status, :duel_type, :duration,
        :timing, :referee_required, :live, :private, :streaming,
        :audience, :parking, :wifi, :lockers, :snacks,
        :home_goals, :away_goals, :hunted, :responsibility
      )
    end
end
