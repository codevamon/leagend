class ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_duel
  before_action :authorize_result_entry!

  def new
    @result = Result.new
  end

  def create
    @result = Result.new(
      id: SecureRandom.uuid,
      duel: @duel,
      home_teamable: @duel.home_team,
      away_teamable: @duel.away_team,
      referee: @duel.referee,
      outcome: result_params[:outcome],
      best_player_id: result_params[:best_player_id].presence
    )

    if @result.save
      @duel.update!(status: :completed)
      redirect_to duel_path(@duel), notice: "Resultado registrado con éxito"
    else
      flash.now[:alert] = @result.errors.full_messages.to_sentence
      render :new
    end
  end

  private

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end

    def authorize_result_entry!
      unless current_user == @duel.referee || current_user == @duel.home_team.try(:captain)
        redirect_to duel_path(@duel), alert: "No estás autorizado para registrar este resultado"
      end
    end

    def result_params
      params.require(:result).permit(:outcome, :best_player_id)
    end
end
