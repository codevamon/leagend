class FreePlayersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_duel, only: [:join, :leave]

  def index
    @available_duels = Duel.available_for_challenge
                          .where("starts_at > ?", Time.current)
                          .order(starts_at: :asc)
  end

  def join
    if @duel.can_join?(current_user)
      if @duel.join_as_free_player(current_user)
        NotificationService.notify_free_player_joined(@duel, current_user)
        redirect_to @duel, notice: "Te has unido al duelo exitosamente"
      else
        redirect_to @duel, alert: "No se pudo unir al duelo"
      end
    else
      redirect_to @duel, alert: "No puedes unirte a este duelo"
    end
  end

  def leave
    lineup = @duel.lineups.find_by(user: current_user)
    
    if lineup&.destroy
      redirect_to @duel, notice: "Has abandonado el duelo"
    else
      redirect_to @duel, alert: "No se pudo abandonar el duelo"
    end
  end

  def my_duels
    @joined_duels = Duel.joins(:lineups)
                       .where(lineups: { user_id: current_user.id })
                       .where("starts_at > ?", Time.current)
                       .order(starts_at: :asc)
  end

  private

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end
end 