class ExploreController < ApplicationController
  before_action :authenticate_user!

  def index
    @upcoming_duels = Duel.upcoming.limit(5)
    @available_arenas = Arena.available_in_next_24h.limit(5)
    @free_players = User.free_players.limit(5)
  end

  def duels
    @duels = Duel.upcoming
                 .includes(:home_team, :away_team, :arena)
                 .order(starts_at: :asc)
                 .page(params[:page])

    @duels = @duels.where(duel_type: params[:type]) if params[:type].present?
    @duels = @duels.where("starts_at >= ?", params[:date]) if params[:date].present?
    @duels = @duels.where(arena_id: params[:arena_id]) if params[:arena_id].present?
  end

  def arenas
    @arenas = Arena.includes(:owner)
                  .order(:name)
                  .page(params[:page])

    @arenas = @arenas.where("address ILIKE ?", "%#{params[:location]}%") if params[:location].present?
    @arenas = @arenas.where(owner_id: params[:owner_id]) if params[:owner_id].present?
  end

  def players
    @players = User.free_players
                  .includes(:profile)
                  .order(:name)
                  .page(params[:page])

    @players = @players.where("profiles.position = ?", params[:position]) if params[:position].present?
    @players = @players.where("profiles.skill_level = ?", params[:skill_level]) if params[:skill_level].present?
  end

  private

    def filter_params
      params.permit(:type, :date, :arena_id, :location, :owner_id, :position, :skill_level)
    end
end 