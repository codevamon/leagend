class ArenasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_arena, only: [:show, :availability]

  def index
    @duel = Duel.find_by(id: params[:duel_id]) if params[:duel_id].present?
    
    @arenas = Arena.order(created_at: :desc)
    
    # Filtros
    @arenas = @arenas.where(status: params[:status]) if params[:status].present?
    @arenas = @arenas.where(city: params[:city]) if params[:city].present?
    @arenas = @arenas.where(rentable: true) if params[:rentable] == "true"
    
    if params[:price_min].present?
      @arenas = @arenas.where("price_per_hour >= ?", params[:price_min])
    end
    
    if params[:price_max].present?
      @arenas = @arenas.where("price_per_hour <= ?", params[:price_max])
    end
    
    if @duel.present?
      @arenas = @arenas.select do |arena|
        arena.available_between?(@duel.starts_at, @duel.ends_at)
      end
    end
  end

  def show
    @arena = Arena.friendly.find(params[:id])
  end

  def availability
    date = Date.parse(params[:date]) if params[:date].present?
    date ||= Date.current
    
    slot_minutes = (params[:slot_minutes] || 60).to_i
    
    service = ArenaAvailabilityService.new(@arena, date: date, slot_minutes: slot_minutes)
    @available_slots = service.call
    
    respond_to do |format|
      format.json { render json: { slots: @available_slots } }
      format.html { render partial: 'availability_slots' }
    end
  end

  def geocode
    country = params[:country]&.strip
    city = params[:city]&.strip
    address = params[:address]&.strip

    if country.blank? || city.blank? || address.blank?
      render json: { error: 'Faltan campos requeridos' }, status: :bad_request
      return
    end

    # Construir query para geocodificación
    query = "#{address}, #{city}, #{country}"
    
    begin
      # Usar Geocoder para buscar la dirección
      results = Geocoder.search(query, limit: 1)
      
      if results.any?
        result = results.first
        render json: { 
          lat: result.latitude, 
          lng: result.longitude 
        }
      else
        render json: { 
          lat: nil, 
          lng: nil,
          message: 'No se encontró la dirección especificada'
        }, status: :not_found
      end
    rescue => e
      Rails.logger.error "Error en geocodificación: #{e.message}"
      render json: { 
        error: 'Error interno en geocodificación',
        lat: nil,
        lng: nil
      }, status: :internal_server_error
    end
  end

  def new
    @arena = Arena.new
    if params[:quick].present? && turbo_frame_request?
      render :new, layout: false
    end
  end

  def create
    @arena = Arena.new(arena_params)
    
    # Asegurar que el usuario tenga un owner
    owner = current_user.owner || Owner.create!(user: current_user, level: :basic)
    @arena.owner = owner

    # Flujo QUICK (desde duels/new con modal Turbo)
    if params[:quick].present?
      respond_to do |format|
        if @arena.save
          @arenas = Arena.order(created_at: :desc).limit(100)
          # Usará app/views/arenas/create.turbo_stream.erb
          format.turbo_stream
          format.html { redirect_to arena_path(@arena), notice: "Arena creada." }
        else
          # Re-render del form dentro del frame "modal"
          format.turbo_stream { 
            render :new, 
            layout: false, 
            status: :unprocessable_entity,
            locals: { quick: true }
          }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
      return
    end

    # Flujo normal (arenas/new → show)
    if @arena.save
      redirect_to @arena, notice: "Arena creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @arena = Arena.friendly.find(params[:id])
    authorize_owner!(@arena)
  end

  def update
    @arena = Arena.friendly.find(params[:id])
    authorize_owner!(@arena)
    
    # separa fotos del resto
    attrs = arena_params.except(:photos)
    
    # Adjuntar fotos limpiando blanks
    if params[:arena][:photos].present?
      files = Array(params[:arena][:photos]).reject { |f| f.blank? }
      @arena.photos.attach(files) if files.any?
    end
    
    if @arena.update(attrs)
      redirect_to @arena, notice: 'Arena actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_arena
    @arena = Arena.friendly.find(params[:id])
  end

  def arena_params
    params.require(:arena).permit(
      :name, :country, :city, :address, :neighborhood,
      :latitude, :longitude, :description, :status, :price_per_hour,
      :prestige, :private, :rentable,
      photos: []
    )
  end

  def authorize_owner!(arena)
    unless arena.owner.user_id == current_user.id
      redirect_to arenas_path, alert: 'No tienes permisos para editar esta arena.'
    end
  end
end
