class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:show, :cancel]

  def create
    @arena = Arena.friendly.find(params[:arena_id])
    
    if @arena.unverified?
      render json: { error: "Seleccionar sin disponibilidad garantizada" }, status: :unprocessable_entity
      return
    end

    # Crear reserva automáticamente desde el wizard
    begin
      starts_at = Time.parse(reservation_params[:starts_at])
      ends_at = starts_at + 60.minutes # Duración por defecto de 60 minutos
      
      @reservation = Reservation.create!(
        reservable: @arena,
        payer: current_user,
        receiver: current_user,
        starts_at: starts_at,
        ends_at: ends_at,
        status: :held, # Estado tentativo desde el wizard
        amount_cents: 0,
        duration_minutes: 60
      )
      
      respond_to do |format|
        format.turbo_stream
        format.json { render json: @reservation, status: :created }
        format.html { redirect_to @reservation, notice: 'Reserva creada exitosamente.' }
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "shared/flash_error", locals: { message: e.message }) }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
        format.html { redirect_to @arena, alert: e.message }
      end
    end
  end

  def show
    @reservation = Reservation.find(params[:id])
  end

  def cancel
    begin
      # Cambiar status a canceled
      @reservation.update!(status: :canceled)
      
      respond_to do |format|
        format.turbo_stream
        format.json { render json: { message: 'Reserva cancelada exitosamente', status: @reservation.status } }
        format.html { redirect_to @reservation, notice: 'Reserva cancelada exitosamente.' }
      end
    rescue => e
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "shared/flash_error", locals: { message: e.message }) }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
        format.html { redirect_to @reservation, alert: e.message }
      end
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.permit(:arena_id, :starts_at, :ends_at)
  end
end
