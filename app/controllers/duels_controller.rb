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
    @home_team_users = @home_team ? @home_team.callups.where(duel: @duel).map(&:user) : []
    @away_team_users = @away_team ? @away_team.callups.where(duel: @duel).map(&:user) : []
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
    Rails.logger.info "=== select_team iniciado ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session duel_data: #{session[:duel_data].inspect}"
    
    # Si vienen parámetros del formulario, actualizar los datos del duelo
    if params[:duel_type].present? || params[:mode].present? || params[:duration].present?
      Rails.logger.info "Procesando parámetros del formulario"
      duel_data = DuelService.prepare_duel_data(params)
      session[:duel_data] = duel_data
      @duel_data = duel_data
      Rails.logger.info "Datos guardados en sesión: #{duel_data.inspect}"
    else
      # Si no hay parámetros, usar los datos existentes de la sesión
      Rails.logger.info "Usando datos de sesión existentes"
      @duel_data = session[:duel_data] || {}
      Rails.logger.info "Datos de sesión: #{@duel_data.inspect}"
      unless @duel_data["duel_type"]
        Rails.logger.info "No hay duel_type en sesión, redirigiendo a when"
        redirect_to when_duels_path, alert: "Debes configurar el tipo de duelo primero."
        return
      end
    end

    @memberships = current_user.memberships.includes(:joinable)
    @team_options = @memberships.select do |m|
      joinable = m.joinable
      joinable.is_a?(Clan) || (joinable.is_a?(Club) && (m.admin? || m.king?))
    end
    
    Rails.logger.info "Team options encontrados: #{@team_options.count}"
  end

  def callup_players
    @duel_type = params[:duel_type]
    @starts_at = params[:starts_at]
    @ends_at = params[:ends_at]
  
    @team = Team.find(params[:team_id]) if params[:team_id].present?
  
    # Calcular mínimo de jugadores requeridos según el tipo de duelo
    @required_players = case @duel_type
      when 'training' then 7
      when 'hobbie' then 5
      else 5
    end

    if @team
      @club_or_clan = @team.joinable
      @members = @club_or_clan.memberships.approved.includes(:user)
      @users = @members.map(&:user)
      @callups = @team.callups
    else
      redirect_to select_team_duels_path, alert: "No se pudo encontrar equipo"
    end
  end
  
  def create_team_and_callup
    result = DuelService.create_team_and_callup(params, current_user)
    
    if result.success?
      redirect_to responsibility_duels_path(team_id: result.data[:team].id)
    else
      redirect_to select_team_duels_path, alert: result.error
    end
  end
  
  def send_callup
    begin
      Rails.logger.info "=== send_callup iniciado ==="
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Current user: #{current_user.slug}"
      
      result = DuelService.send_callup(params, current_user)
      
      Rails.logger.info "Result success?: #{result.success?}"
      
      if result.success?
        @user = User.find(params[:user_id])
        @team = Team.find(params[:team_id])
        @callups = @team.callups
        
        Rails.logger.info "Callup creado exitosamente para #{@user.slug}"
      else
        Rails.logger.error "Error en send_callup: #{result.error}"
      end
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path, notice: (result.success? ? result.message : result.error) }
      end
    rescue => e
      Rails.logger.error "Excepción en send_callup: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("callup-feedback", 
          "<div class='alert alert-danger'>Error al enviar convocatoria: #{e.message}</div>") }
        format.html { redirect_back fallback_location: root_path, alert: "Error al enviar convocatoria: #{e.message}" }
      end
    end
  end
  
  def send_callups_to_all
    begin
      Rails.logger.info "=== send_callups_to_all iniciado ==="
      Rails.logger.info "Params: #{params.inspect}"
      Rails.logger.info "Current user: #{current_user.slug}"
      
      result = DuelService.send_callups_to_all(params, current_user)
      
      Rails.logger.info "Result success?: #{result.success?}"
      
      if result.success?
        @team = Team.find(params[:team_id])
        @callups = @team.callups
        
        Rails.logger.info "Callups creados exitosamente para el equipo #{@team.name}"
      else
        Rails.logger.error "Error en send_callups_to_all: #{result.error}"
      end
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path, notice: (result.success? ? result.message : result.error) }
      end
    rescue => e
      Rails.logger.error "Excepción en send_callups_to_all: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update("callup-feedback", 
          "<div class='alert alert-danger'>Error al enviar convocatorias: #{e.message}</div>") }
        format.html { redirect_back fallback_location: root_path, alert: "Error al enviar convocatorias: #{e.message}" }
      end
    end
  end

  def manage
    @duel = Duel.includes(:home_team, :away_team, :arena, :callups, :lineups).find(params[:id])
    @home_team_users = @duel.home_team ? @duel.home_team.callups.where(duel: @duel).map(&:user) : []
    @away_team_users = @duel.away_team ? @duel.away_team.callups.where(duel: @duel).map(&:user) : []

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
    Rails.logger.info "=== responsibility iniciado ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session duel_data: #{session[:duel_data].inspect}"
    
    @team = Team.find(params[:team_id]) if params[:team_id].present?
    Rails.logger.info "Team encontrado: #{@team&.name}"
    
    unless @team
      Rails.logger.info "No se encontró equipo, redirigiendo a select_team"
      redirect_to select_team_duels_path, alert: "No se especificó ningún equipo."
      return
    end
    
    # Verificar que tengamos datos de sesión
    @duel_data = session[:duel_data] || {}
    Rails.logger.info "Datos de sesión en responsibility: #{@duel_data.inspect}"
    unless @duel_data["duel_type"]
      Rails.logger.info "No hay duel_type en sesión, redirigiendo a when"
      redirect_to when_duels_path, alert: "Debes configurar el tipo de duelo primero."
      return
    end
    
    Rails.logger.info "Responsibility completado exitosamente"
  end

  def finalize_creation
    team = Team.find(params[:team_id])
    duel_data = session[:duel_data] || {}

    # Crear el duelo con los datos de la sesión
    starts_at = if duel_data["starts_at"]
      if duel_data["starts_at"].is_a?(String)
        Time.zone.parse(duel_data["starts_at"])
      elsif duel_data["starts_at"].is_a?(ActiveSupport::TimeWithZone) || duel_data["starts_at"].is_a?(Time) || duel_data["starts_at"].is_a?(DateTime)
        duel_data["starts_at"]
      else
        Time.zone.parse(duel_data["starts_at"].to_s)
      end
    else
      1.hour.from_now
    end
    
    ends_at = if duel_data["ends_at"]
      if duel_data["ends_at"].is_a?(String)
        Time.zone.parse(duel_data["ends_at"])
      elsif duel_data["ends_at"].is_a?(ActiveSupport::TimeWithZone) || duel_data["ends_at"].is_a?(Time) || duel_data["ends_at"].is_a?(DateTime)
        duel_data["ends_at"]
      else
        Time.zone.parse(duel_data["ends_at"].to_s)
      end
    else
      2.hours.from_now
    end
    
    duel = Duel.create!(
      home_team: team,
      duel_type: duel_data["duel_type"] || :friendly,
      starts_at: starts_at,
      ends_at: ends_at,
      status: :pending,
      temporary: true,
      expires_at: starts_at + 24.hours
    )

    # Asignar árbitro automáticamente
    RefereeAssigner.assign_to_duel(duel)

    # Enviar notificaciones
    NotificationService.notify_duel_created(duel)

    # Limpiar los datos de la sesión
    session.delete(:duel_data)

    redirect_to manage_duel_path(duel), notice: "¡Duelo creado exitosamente! El equipo #{team.name} está listo para jugar. Ahora puedes convocar jugadores desde el panel de gestión."
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
    @duel = Duel.find(params[:id])
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
