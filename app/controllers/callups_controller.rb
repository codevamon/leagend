class CallupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: [:new, :create]
  before_action :set_duel, only: [:new, :create]
  

  def new
    @users = @team.users
  end

  def create
    user = User.find(params[:user_id])

    callup = Callup.new(
      user: user,
      duel: @duel,
      teamable: @team
    )

    if callup.save
      Notification.create!(
        recipient: user,
        sender: @team,
        category: :callup,
        message: "Fuiste convocado al duelo por el equipo #{@team.name}.",
        notifiable: callup
      )
      redirect_to @team, notice: 'Usuario convocado exitosamente.'
    else
      redirect_to @team, alert: 'Error al convocar usuario.'
    end
  end

  def accept
    callup = current_user.callups.find_by(id: params[:callup_id])
    if callup&.pending?
      callup.update!(status: :accepted)
      Lineup.create!(
        duel: callup.duel,
        user: current_user,
        teamable_id: callup.teamable_id,
        teamable_type: callup.teamable_type
      )
  
      Notification.create!(
        recipient: callup.teamable.captain,
        sender: current_user,
        category: :callup,
        message: "#{current_user.slug} ha aceptado la convocatoria para el duelo.",
        notifiable: callup.duel
      )
  
      flash[:notice] = "Has aceptado la convocatoria."
    end
    redirect_to duel_path(callup.duel_id)
  end
  
  def reject
    callup = current_user.callups.find_by(id: params[:callup_id])
    if callup&.pending?
      callup.update!(status: :rejected)
  
      Notification.create!(
        recipient: callup.teamable.captain,
        sender: current_user,
        category: :callup,
        message: "#{current_user.slug} ha rechazado la convocatoria.",
        notifiable: callup.duel
      )
  
      flash[:alert] = "Has rechazado la convocatoria."
    end
    redirect_to notifications_path
  end
  

  private

    def set_team
      @team = Team.find(params[:team_id])
    end

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end
end