module Api
  module V1
    class ArenasController < ApplicationController
      before_action :set_arena, only: [:show, :availability]

      def index
        @arenas = Arena.with_attached_photos
        
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
        
        render json: @arenas
      end

      def show
        render json: @arena
      end

      def availability
        date = Date.parse(params[:date]) if params[:date].present?
        date ||= Date.current
        
        slot_minutes = (params[:slot_minutes] || 60).to_i
        
        service = ArenaAvailabilityService.new(@arena, date: date, slot_minutes: slot_minutes)
        available_slots = service.call
        
        render json: { slots: available_slots }
      end

      private

      def set_arena
        @arena = Arena.friendly.find(params[:id])
      end
    end
  end
end
