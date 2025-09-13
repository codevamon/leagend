class DuelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_duel, only: [:show, :update, :manage, :start, :randomize_teams]
  before_action :authorize_duel_management, only: [:manage, :start, :randomize_teams]

  # 🔹 FLUJO SIMPLIFICADO - MVP
  def new
    @duel   = Duel.new
    @arenas = Arena.order(:name)
  end

    def create
    ActiveRecord::Base.transaction do
      # Crear duelo sin equipo asignado inicialmente
      duel_attributes = normalized_duel_params
      
      # Log temporal para verificar parámetros de ubicación
      Rails.logger.info("[Duels#create] loc=#{normalized_duel_params.slice(:country,:city,:address,:neighborhood,:latitude,:longitude)}")
      
      # Si hay arena seleccionada, copiar su ubicación al duelo
      if duel_attributes[:arena_id].present?
        arena = Arena.find(duel_attributes[:arena_id])
        if arena
          # Sobrescribir ubicación del duelo con la de la arena
          duel_attributes[:country] = arena.country
          duel_attributes[:city] = arena.city
          duel_attributes[:address] = arena.address
          duel_attributes[:neighborhood] = arena.neighborhood
          duel_attributes[:latitude] = arena.latitude
          duel_attributes[:longitude] = arena.longitude
          
          Rails.logger.info("[Duels#create] Arena seleccionada: #{arena.name}, ubicación copiada")
        end
      end
      
      # Limpiar arena_id si está vacío
      duel_attributes[:arena_id] = nil if duel_attributes[:arena_id].blank?
      @duel = Duel.new(duel_attributes)
      @duel.status = 'open' # Por defecto abierto para desafíos
      
      # Calcular ends_at si se proporciona duration_minutes
      if params[:duel][:duration_minutes].present? && @duel.starts_at.present?
        duration_minutes = params[:duel][:duration_minutes].to_i
        @duel.ends_at = @duel.starts_at + duration_minutes.minutes
      end
      
      if @duel.save!
        # Crear equipo temporal automáticamente
        team = Team.create!(
          name: "Equipo de #{current_user.firstname}",
          captain: current_user,
          temporary: true,
          expires_at: @duel.starts_at + 24.hours
        )
        
        # Asignar el equipo temporal al duelo
        @duel.update!(home_team: team)
        
        # Crear Reservation si hay arena seleccionada
        if duel_attributes[:arena_id].present? && arena
          Reservation.create!(
            reservable: arena,
            payer: current_user,
            receiver: arena.owner.user,
            starts_at: @duel.starts_at,
            ends_at: @duel.ends_at,
            status: 'held',
            amount_cents: 0,
            currency: 'COP'
          )
          Rails.logger.info("[Duels#create] Reservation creada para Arena: #{arena.name}")
        end
        
        # Asignar árbitro si se solicita
        RefereeAssigner.assign_to_duel(@duel) if params[:assign_referee] == '1'
        
        redirect_to @duel, notice: 'Duelo creado exitosamente. Ahora puedes convocar jugadores.'
      end
    end
    
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    load_arenas_for_form
    render :new
  rescue => e
    flash.now[:alert] = "Error al crear el duelo: #{e.message}"
    load_arenas_for_form
    render :new
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

  # app/controllers/duels_controller.rb

  def self_callup_captain
    @duel = Duel.find(params[:id])
    @team = @duel.home_team
    
    unless @team.present? && current_user == @team.captain
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("flash_messages", 
            partial: "shared/flash", locals: { type: "alert", message: "No tienes permisos para autoconvocarte." })
        }
        format.html { redirect_to available_players_duel_path(@duel), alert: "No tienes permisos para autoconvocarte." }
      end
      return
    end

    # Evitar duplicados
    unless @duel.callups.exists?(user: current_user, teamable: @team)
      @duel.callups.create!(
        user: current_user,
        teamable: @team,
        status: :accepted
      )
      Lineup.create!(
        duel: @duel,
        user: current_user,
        teamable: @team
      )
    end

    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.replace(
            "callup_button_#{current_user.id}",
            partial: "duels/callup_button", 
            locals: { player: current_user, team: @team, duel: @duel }
          ),
          turbo_stream.update("flash_messages", 
            partial: "shared/flash", locals: { type: "notice", message: "Te has autoconvocado exitosamente como capitán." })
        ]
      }
      format.html { redirect_to available_players_duel_path(@duel), notice: "Te has autoconvocado exitosamente como capitán." }
    end
  end

  # 🔹 FLUJO LEGACY (DEPRECATED - Solo para compatibilidad)
  def when
    redirect_to new_duel_path, notice: "Flujo simplificado. Usa 'Crear Duelo' directamente."
  end

  def select_team
    redirect_to new_duel_path, notice: "Flujo simplificado. Usa 'Crear Duelo' directamente."
  end

  def callup_players
    redirect_to @duel, notice: "Gestiona las convocatorias desde el panel del duelo."
  end

  def select_arena
    redirect_to @duel, notice: "Selecciona la arena desde el panel de gestión."
  end

  def select_type
    redirect_to @duel, notice: "Configura el tipo desde el panel de gestión."
  end

  def confirm
    redirect_to @duel, notice: "El duelo ya está creado. Gestiona desde el panel."
  end

  def finalize_creation
    @duel = Duel.find(params[:id])
    
    # Buscar la reserva held asociada al duelo
    reservation = Reservation.find_by(
      reservable: @duel.arena,
      payer: current_user,
      receiver: current_user,
      starts_at: @duel.starts_at,
      status: :held
    )
    
    if reservation
      # Confirmar la reserva
      reservation.update!(status: :reserved)
      Rails.logger.info("[Duels#finalize_creation] Reserva confirmada: #{reservation.id}")
    else
      Rails.logger.warn("[Duels#finalize_creation] No se encontró reserva held para el duelo #{@duel.id}")
    end
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @duel, notice: 'Duelo finalizado exitosamente.' }
      format.json { render json: { status: 'success', message: 'Duelo finalizado exitosamente.' } }
    end
  end

  # 🔹 GESTIÓN DE DUELOS
  def manage
    @home_team_users = @duel.home_team ? @duel.home_team.callups.where(duel: @duel).includes(:user) : []
    @away_team_users = @duel.away_team ? @duel.away_team.callups.where(duel: @duel).includes(:user) : []
    @free_players = @duel.free_players.limit(20)
  end

  def start
    if @duel.can_start?
      @duel.update!(status: 'ongoing')
      NotificationService.notify_duel_started(@duel)
      redirect_to @duel, notice: 'Duelo iniciado exitosamente.'
    else
      redirect_to @duel, alert: 'No se puede iniciar el duelo. Verifica que tengas suficientes jugadores.'
    end
  end

  def randomize_teams
    if @duel.can_randomize_teams?
      DuelService.randomize_teams(@duel)
      redirect_to @duel, notice: 'Equipos aleatorizados exitosamente.'
    else
      redirect_to @duel, alert: 'No se pueden aleatorizar los equipos en este momento.'
    end
  end

  def postpone
    @duel = Duel.find(params[:id])
    
    unless @duel.can_be_postponed?
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("flash_messages", 
            partial: "shared/flash", locals: { type: "alert", message: "No se puede postergar este duelo en este momento." })
        }
        format.html { redirect_to manage_duel_path(@duel), alert: "No se puede postergar este duelo en este momento." }
      end
      return
    end

    hours_to_add = params[:hours].to_i
    
    unless [1, 2, 4, 8, 12, 24].include?(hours_to_add)
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("flash_messages", 
            partial: "shared/flash", locals: { type: "alert", message: "Tiempo de postergación inválido." })
        }
        format.html { redirect_to manage_duel_path(@duel), alert: "Tiempo de postergación inválido." }
      end
      return
    end

    ActiveRecord::Base.transaction do
      # Calcular la nueva duración original
      original_duration = @duel.ends_at - @duel.starts_at
      
      # Actualizar starts_at
      @duel.starts_at += hours_to_add.hours
      
      # Actualizar ends_at manteniendo la misma duración
      @duel.ends_at = @duel.starts_at + original_duration
      
      # Cambiar status a postponed
      @duel.status = :postponed
      
      if @duel.save!
        # Notificar a los jugadores convocados sobre el cambio de horario
        notify_players_about_postponement(hours_to_add)
        
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: [
              turbo_stream.replace(
                "duel_details_section",
                partial: "duels/duel_details_section",
                locals: { duel: @duel }
              ),
              turbo_stream.update("flash_messages", 
                partial: "shared/flash", locals: { type: "notice", message: "Duelo postergado exitosamente por #{hours_to_add} horas." })
            ]
          }
          format.html { redirect_to manage_duel_path(@duel), notice: "Duelo postergado exitosamente por #{hours_to_add} horas." }
        end
      end
    end
  rescue => e
    Rails.logger.error "Error al postergar duelo: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update("flash_messages", 
          partial: "shared/flash", locals: { type: "alert", message: "Error al postergar el duelo: #{e.message}" })
      }
      format.html { redirect_to manage_duel_path(@duel), alert: "Error al postergar el duelo: #{e.message}" }
    end
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



  # Nueva acción para mostrar jugadores disponibles
  def available_players
    @duel = Duel.find(params[:id])
    @team = @duel.home_team
    
    unless @team.present?
      redirect_to manage_duel_path(@duel), alert: "No hay equipo asignado."
      return
    end

    # Obtener TODOS los usuarios de la plataforma (incluyendo al capitán)
    @all_users = User.includes(:memberships, :avatar_attachment)
                     .order(:firstname, :lastname)
    
    # Obtener clubs y clanes del usuario para asociación
    @user_clubs = current_user.memberships.includes(:joinable).map(&:joinable).select { |j| j.is_a?(Club) }
    @user_clans = current_user.memberships.includes(:joinable).map(&:joinable).select { |j| j.is_a?(Clan) }
  end

  # Acción para convocar jugador
  def callup_player
    @duel = Duel.find(params[:id])
    @team = @duel.home_team
    @user = User.find(params[:user_id])
    
    unless @team.present?
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.update("flash_messages", 
            partial: "shared/flash", locals: { type: "alert", message: "No hay equipo asignado." })
        }
        format.html { redirect_to manage_duel_path(@duel), alert: "No hay equipo asignado." }
        format.json { render json: { status: 'error', message: 'No hay equipo asignado.' } }
      end
      return
    end

    # Verificar si ya existe una convocatoria
    existing_callup = @team.callups.find_by(user: @user, duel: @duel)
    
    if existing_callup
      if existing_callup.pending?
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update("flash_messages", 
              partial: "shared/flash", locals: { type: "alert", message: 'Jugador ya convocado' })
          }
          format.html { redirect_to available_players_duel_path(@duel), alert: 'Jugador ya convocado' }
          format.json { render json: { status: 'already_pending', message: 'Jugador ya convocado' } }
        end
      elsif existing_callup.accepted?
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: turbo_stream.update("flash_messages", 
              partial: "shared/flash", locals: { type: "alert", message: 'Jugador ya confirmado' })
          }
          format.html { redirect_to available_players_duel_path(@duel), alert: 'Jugador ya confirmado' }
          format.json { render json: { status: 'already_accepted', message: 'Jugador ya confirmado' } }
        end
      else
        # Rechazado, crear nueva convocatoria
        existing_callup.update!(status: :pending)
        NotificationService.notify_callup_sent(@user, @team, @duel)
        
        respond_to do |format|
          format.turbo_stream { 
            render turbo_stream: [
              turbo_stream.replace(
                "callup_button_#{@user.id}",
                partial: "duels/callup_button", 
                locals: { player: @user, team: @team, duel: @duel }
              ),
              turbo_stream.update("flash_messages", 
                partial: "shared/flash", locals: { type: "notice", message: 'Jugador convocado nuevamente' })
            ]
          }
          format.html { redirect_to available_players_duel_path(@duel), notice: 'Jugador convocado nuevamente' }
          format.json { render json: { status: 'success', message: 'Jugador convocado nuevamente' } }
        end
      end
    else
      # Crear nueva convocatoria
      callup = @team.callups.create!(
        user: @user,
        duel: @duel,
        status: :pending
      )
      NotificationService.notify_callup_sent(@user, @team, @duel)
      
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.replace(
              "callup_button_#{@user.id}",
              partial: "duels/callup_button", 
              locals: { player: @user, team: @team, duel: @duel }
            ),
            turbo_stream.update("flash_messages", 
              partial: "shared/flash", locals: { type: "notice", message: 'Jugador convocado exitosamente' })
          ]
        }
        format.html { redirect_to available_players_duel_path(@duel), notice: 'Jugador convocado exitosamente' }
        format.json { render json: { status: 'success', message: 'Jugador convocado exitosamente' } }
      end
    end
  rescue => e
    Rails.logger.error "Error en callup_player: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update("flash_messages", 
          partial: "shared/flash", locals: { type: "alert", message: "Error al convocar jugador: #{e.message}" })
      }
      format.html { redirect_to available_players_duel_path(@duel), alert: "Error al convocar jugador: #{e.message}" }
      format.json { render json: { status: 'error', message: e.message } }
    end
  end

  # Acción para habilitar/deshabilitar freeplayers
  def toggle_freeplayers
    @duel = Duel.find(params[:id])
    @duel.update!(allow_freeplayers: !@duel.allow_freeplayers)
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.update("freeplayers_toggle", 
          partial: "duels/freeplayers_toggle", locals: { duel: @duel })
      }
      format.html { redirect_to available_players_duel_path(@duel), notice: "Configuración de jugadores libres actualizada." }
    end
  end

  # Acción para asociar duelo a club
  def associate_with_club
    @duel = Duel.find(params[:id])
    @club = Club.find(params[:club_id])
    
    # Verificar que el usuario sea miembro del club
    unless current_user.memberships.exists?(joinable: @club)
      redirect_to available_players_duel_path(@duel), alert: "Debes ser miembro del club para asociarlo."
      return
    end
    
    membership = current_user.memberships.find_by(joinable: @club)
    
    if membership.admin?
      # Si es admin, asociación inmediata
      @duel.update!(club: @club, club_association_pending: false)
      redirect_to available_players_duel_path(@duel), notice: "Duelo asociado al club #{@club.name} exitosamente."
    else
      # Si no es admin, enviar notificación al admin
      @duel.update!(club: @club, club_association_pending: true)
      
      # Notificar al admin del club
      club_admin = @club.user
      Notification.create!(
        recipient: club_admin,
        sender: current_user,
        category: :club_association,
        message: "#{current_user.firstname} solicita asociar un duelo al club #{@club.name}",
        notifiable: @duel
      )
      
      redirect_to available_players_duel_path(@duel), notice: "Solicitud de asociación enviada al admin del club. Pendiente de aprobación."
    end
  end

  # Acción para asociar duelo a clan
  def associate_with_clan
    @duel = Duel.find(params[:id])
    @clan = Clan.find(params[:clan_id])
    
    # Verificar que el usuario sea miembro del clan
    unless current_user.memberships.exists?(joinable: @clan)
      redirect_to available_players_duel_path(@duel), alert: "Debes ser miembro del clan para asociarlo."
      return
    end
    
    # Asociación inmediata para clanes
    @duel.update!(clan: @clan)
    redirect_to available_players_duel_path(@duel), notice: "Duelo asociado al clan #{@clan.name} exitosamente."
  end

  # Acción para aprobar/rechazar asociación de club
  def approve_club_association
    @duel = Duel.find(params[:id])
    
    # Verificar que el usuario sea admin del club
    unless current_user.memberships.exists?(joinable: @duel.club, admin: true)
      redirect_to notifications_path, alert: "No tienes permisos para aprobar esta asociación."
      return
    end
    
    @duel.update!(club_association_pending: false)
    
    # Notificar al solicitante
    if @duel.home_team&.captain
      Notification.create!(
        recipient: @duel.home_team.captain,
        sender: current_user,
        category: :club_association,
        message: "Tu solicitud de asociación al club #{@duel.club.name} ha sido aprobada",
        notifiable: @duel
      )
    end
    
    redirect_to notifications_path, notice: "Asociación de club aprobada exitosamente."
  end

  def reject_club_association
    @duel = Duel.find(params[:id])
    
    # Verificar que el usuario sea admin del club
    unless current_user.memberships.exists?(joinable: @duel.club, admin: true)
      redirect_to notifications_path, alert: "No tienes permisos para rechazar esta asociación."
      return
    end
    
    # Notificar al solicitante
    if @duel.home_team&.captain
      Notification.create!(
        recipient: @duel.home_team.captain,
        sender: current_user,
        category: :club_association,
        message: "Tu solicitud de asociación al club #{@duel.club.name} ha sido rechazada",
        notifiable: @duel
      )
    end
    
    # Remover la asociación
    @duel.update!(club: nil, club_association_pending: false)
    
    redirect_to notifications_path, notice: "Asociación de club rechazada."
  end

  private

  def set_duel
    @duel = Duel.find(params[:id])
  end

  def authorize_duel_management
    unless current_user.present? && @duel.can_be_managed_by?(current_user)
      redirect_to root_path, alert: "No tienes permiso para gestionar este duelo."
    end
  end

  def duel_params
    params.require(:duel).permit(
      :away_team_id, :arena_id, :starts_at, :ends_at, :duration_minutes, :duel_type, :private, :status, :challenge_type,
      :country, :city, :address, :neighborhood, :latitude, :longitude,
      :price, :budget, :budget_place, :assign_referee, :type_of_duel
    )
  end

  def normalized_duel_params
    p = duel_params.to_h

    # Normaliza strings vacíos a nil en campos de ubicación
    %w[country city address neighborhood].each do |k|
      v = p[k]
      p[k] = v.present? ? v.to_s.strip : nil
    end

    # Cast numérico y redondeo razonable
    p['latitude']  = p['latitude'].presence  && BigDecimal(p['latitude'].to_s).round(6)
    p['longitude'] = p['longitude'].presence && BigDecimal(p['longitude'].to_s).round(6)

    p.symbolize_keys
  end

  def load_arenas_for_form
    @arenas = Arena.order(:name)
  end

  def notify_players_about_postponement(hours_added)
    # Notificar a todos los jugadores convocados (aceptados y pendientes)
    all_convoked_users = @duel.callups.includes(:user).map(&:user).uniq
    
    all_convoked_users.each do |user|
      Notification.create!(
        recipient: user,
        sender: current_user,
        category: :duel_postponed,
        message: "El duelo '#{@duel.duel_type.titleize}' ha sido postergado por #{hours_added} horas. Nueva hora: #{l(@duel.starts_at, format: :long)}",
        notifiable: @duel
      )
    end
  end
end
