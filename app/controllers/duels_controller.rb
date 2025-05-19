class DuelsController < ApplicationController
  before_action :set_teams, only: [:new, :create]
  before_action :set_duel, only: [:show, :update, :manage, :start, :add_goal, :randomize_teams]
  before_action :authorize_duel_management, only: [:manage, :start, :add_goal, :randomize_teams]

  # 🔹 Clásicos
  def new
    @duel = Duel.new
  end

  def create
    @duel = Duel.new(duel_params)
    
    if @duel.save
      RefereeAssigner.assign_to_duel(@duel)
      NotificationService.notify_duel_created(@duel)
      redirect_to @duel, notice: 'Duelo creado exitosamente.'
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :new
    end
  end

  def show
    @home_team = @duel.home_team
    @away_team = @duel.away_team
    @home_team_users = @duel.callups.where(teamable: @home_team).map(&:user)
    @away_team_users = @duel.callups.where(teamable: @away_team).map(&:user)
    @challenge = Challenge.find_by(challenger_duel_id: @duel.id) || Challenge.find_by(challengee_duel_id: @duel.id)
    
    if @duel.can_be_challenged?
      @desafiables = Duel.where(arena: nil, away_team_id: nil, status: "open")
                        .where.not(id: @duel.id)
                        .where("ABS(strftime('%s', duels.starts_at) - strftime('%s', ?)) <= ?", @duel.starts_at, 24.hours.to_i)
    end
  end

  def my_duels
    @duels = DuelService.fetch_user_duels(current_user)
                        .order(starts_at: :desc)
  end

  def update
    if @duel.update(duel_params)
      NotificationService.notify_duel_updated(@duel)
      redirect_to @duel, notice: "Duelo actualizado exitosamente."
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :edit
    end
  end

  # 🔹 Flujo personalizado paso a paso
  def when
    @duel = Duel.new
  end

  def select_team
    duel_data = DuelService.prepare_duel_data(params)
    session[:duel_data] = duel_data

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
    result = DuelService.create_team_and_callup(params, current_user)
    
    if result.success?
      redirect_to callup_players_duels_path(
        team_id: result.data[:team].id,
        duel_type: params[:duel_type],
        starts_at: params[:starts_at],
        ends_at: params[:ends_at]
      )
    else
      redirect_to select_team_duels_path, alert: result.error
    end
  end
  
  def send_callup
    result = DuelService.send_callup(params, current_user)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path, notice: (result.success? ? result.message : result.error) }
    end
  end
  
  def send_callups_to_all
    result = DuelService.send_callups_to_all(params, current_user)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path, notice: (result.success? ? result.message : result.error) }
    end
  end

  def manage
    @duel = Duel.includes(:home_team, :away_team, :arena, :callups, :lineups).find(params[:id])
    @home_team_users = @duel.callups.where(teamable: @duel.home_team).map(&:user)
    @away_team_users = @duel.callups.where(teamable: @duel.away_team).map(&:user)

    # Flags para la vista
    @expired = @duel.expired?
    @desafiable = @duel.desafiable?
    @desafiante = @duel.desafiante?
    @allows_freeplayers = @duel.allows_freeplayers?
  end

  def start
    if @duel.can_start?
      @duel.start!
      NotificationService.notify_duel_started(@duel)
      redirect_to @duel, notice: "El duelo ha comenzado."
    else
      redirect_to manage_duel_path(@duel), alert: "No se puede iniciar el duelo: #{@duel.errors.full_messages.to_sentence}"
    end
  end

  def add_goal
    result = DuelService.add_goal(@duel, params[:team_id], params[:user_id])
    
    if result.success?
      redirect_to manage_duel_path(@duel), notice: "Gol registrado exitosamente."
    else
      redirect_to manage_duel_path(@duel), alert: result.error
    end
  end

  def randomize_teams
    if @duel.can_randomize_teams?
      result = DuelService.randomize_teams(@duel)
      redirect_to manage_duel_path(@duel), notice: "Equipos aleatorizados exitosamente."
    else
      redirect_to manage_duel_path(@duel), alert: "No se pueden aleatorizar los equipos en este momento."
    end
  end

  def responsibility
    @team = Team.find(params[:team_id]) if params[:team_id].present?
  end

  def finalize_creation
    team = Team.find(params[:team_id])
    duel_data = session[:duel_data] || {}

    # Crear el duelo
    duel = Duel.create!(
      home_team: team,
      duel_type: duel_data[:duel_type] || :friendly,
      starts_at: duel_data[:starts_at] || 1.hour.from_now,
      ends_at: duel_data[:ends_at] || 2.hours.from_now,
      status: :pending
    )

    # Crear lineups para los usuarios convocados y aceptados
    accepted_callups = Callup.where(teamable: team, status: :accepted)
    accepted_callups.each do |callup|
      Lineup.find_or_create_by!(duel: duel, user: callup.user, teamable: team)
    end

    # Limpiar los datos de la sesión
    session.delete(:duel_data)

    redirect_to duel_path(duel), notice: "Duelo creado y responsabilidad aceptada para el equipo #{team.name}."
  end

  # Acción para publicar el duelo en Explore (jugadores libres)
  def publish_for_freeplayers
    @duel = Duel.find(params[:id])
    # Aquí podrías cambiar un flag o estado si lo necesitas
    # Por ejemplo: @duel.update!(published_for_freeplayers: true)
    redirect_to manage_duel_path(@duel), notice: "Duelo publicado para jugadores libres."
  end

  # Acción para aceptar a un jugador libre
  def accept_freeplayer
    @duel = Duel.find(params[:id])
    user = User.find(params[:user_id])
    team = @duel.home_team
    callup = Callup.create!(user: user, teamable: team, duel: @duel, status: :accepted)
    Lineup.create!(duel: @duel, user: user, teamable: team)
    redirect_to manage_duel_path(@duel), notice: "Jugador libre aceptado y alineado."
  end

  private

  def set_duel
    @duel = Duel.friendly.find(params[:id])
  end

  def authorize_duel_management
    unless @duel.can_be_managed_by?(current_user)
      redirect_to root_path, alert: "No tienes permiso para gestionar este duelo."
    end
  end

  def duel_params
    params.require(:duel).permit(
      :home_team_id, :away_team_id, :arena_id, :starts_at, :ends_at,
      :duel_type, :mode, :duration, :private, :status, :challenge_type
    )
  end
end
