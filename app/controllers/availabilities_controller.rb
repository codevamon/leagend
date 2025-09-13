class AvailabilitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_availability, only: [:show, :update, :destroy]

  def index
    @availabilities = Availability.all
  end

  def show
  end

  def new
    @availability = Availability.new
  end

  def create
    @availability = Availability.new(availability_params)
    @availability.availablable = current_user

    respond_to do |format|
      if @availability.save
        format.turbo_stream
        format.html { redirect_to @availability, notice: 'Disponibilidad creada exitosamente.' }
        format.json { render json: @availability, status: :created }
      else
        format.html { render :new }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @availability.update(availability_params)
        format.turbo_stream
        format.html { redirect_to @availability, notice: 'Disponibilidad actualizada exitosamente.' }
        format.json { render json: @availability }
      else
        format.html { render :edit }
        format.json { render json: @availability.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @availability.destroy
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to availabilities_url, notice: 'Disponibilidad eliminada exitosamente.' }
      format.json { head :no_content }
    end
  end

  private

  def set_availability
    @availability = Availability.find(params[:id])
  end

  def availability_params
    params.require(:availability).permit(:starts_at, :ends_at, :reason, :status)
  end
end
