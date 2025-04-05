class ArenasController < ApplicationController
  before_action :authenticate_user!

  def index
    @duel = Duel.find_by(id: params[:duel_id]) if params[:duel_id].present?
    
    if @duel.present?
      @arenas = Arena.all.select do |arena|
        arena.available_between?(@duel.starts_at, @duel.ends_at)
      end
    else
      @arenas = Arena.all
    end
  end

  def show
    @arena = Arena.friendly.find(params[:id])
  end
end
