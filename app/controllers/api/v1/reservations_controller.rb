module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_reservation, only: [:cancel]

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
          
          render json: @reservation, status: :created
        rescue => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      def cancel
        service = ArenaReservationService.new
        service.cancel(reservation: @reservation)
        
        render json: { message: 'Reserva cancelada' }
      end

      private

      def set_reservation
        @reservation = Reservation.find(params[:id])
      end

      def reservation_params
        params.require(:reservation).permit(:starts_at, :ends_at)
      end
    end
  end
end
