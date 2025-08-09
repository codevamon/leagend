class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:show, :cancel]

  def create
    @arena = Arena.friendly.find(params[:arena_id])
    
    if @arena.unverified?
      render json: { error: "Seleccionar sin disponibilidad garantizada" }, status: :unprocessable_entity
      return
    end

    service = ArenaReservationService.new
    
    begin
      @reservation = service.reserve(
        arena: @arena,
        user: current_user,
        starts_at: reservation_params[:starts_at],
        ends_at: reservation_params[:ends_at]
      )
      
      respond_to do |format|
        format.json { render json: @reservation, status: :created }
        format.html { redirect_to @reservation, notice: 'Reserva creada exitosamente.' }
      end
    rescue => e
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
        format.html { redirect_to @arena, alert: e.message }
      end
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def cancel
    service = ArenaReservationService.new
    service.cancel(reservation: @reservation)
    
    respond_to do |format|
      format.json { render json: { message: 'Reserva cancelada' } }
      format.html { redirect_to @reservation, notice: 'Reserva cancelada exitosamente.' }
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(:starts_at, :ends_at)
  end
end
