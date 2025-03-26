class LineupsController < ApplicationController
  before_action :set_duel
  before_action :set_lineup, only: [:edit, :update]
  before_action :authorize_edit!, only: [:edit, :update]

  def index
    @lineups = @duel.lineups.includes(:user)
  end

  def edit
  end

  def update
    if @lineup.update(lineup_params)
      redirect_to duel_lineups_path(@duel), notice: "Alineación actualizada"
    else
      flash.now[:alert] = @lineup.errors.full_messages.to_sentence
      render :edit
    end
  end

  private

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end

    def set_lineup
      @lineup = @duel.lineups.find_by!(id: params[:id])

    end

    def authorize_edit!
      unless @lineup.teamable.respond_to?(:captain_id) && @lineup.teamable.captain_id == current_user.id
        redirect_to duel_lineups_path(@duel), alert: "No autorizado"
      end
    end

    def lineup_params
      params.require(:lineup).permit(:position, :formation)
    end
end
