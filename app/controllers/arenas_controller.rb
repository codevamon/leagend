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

  def new
    @arena = Arena.new
    # Render sin layout dentro del turbo-frame del modal quick
    render layout: false if params[:quick].present? && turbo_frame_request?
  end

  def create
    owner = current_user.owner || Owner.create!(user: current_user, level: :basic)

    attrs  = arena_params.except(:photos)
    @arena = owner.arenas.new(attrs.merge(status: "unverified"))

    if params[:arena][:photos].present?
      files = Array(params[:arena][:photos]).reject(&:blank?)
      @arena.photos.attach(files) if files.any?
    end

    if @arena.save
      if params[:quick].present? || turbo_frame_request?
        # Respuesta para el modal desde duels/new:
        @arenas = Arena.order(:name)
        @selected_arena_id = @arena.id
        render turbo_stream: [
          turbo_stream.replace("arena_quick_new", ""), # cierra modal
          turbo_stream.replace(
            "arena_select_frame",
            partial: "duels/arena_select",
            locals: { arenas: @arenas, selected_arena_id: @selected_arena_id }
          )
        ]
      else
        redirect_to @arena, notice: "Arena creada."
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
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
      :name, :address, :neighborhood, :city, :country, :latitude, :longitude,
      photos: [] # solo para filtrarla, no para asignación masiva
    )
  end

  def authorize_owner!(arena)
    unless arena.owner.user_id == current_user.id
      redirect_to arenas_path, alert: 'No tienes permisos para editar esta arena.'
    end
  end
end
