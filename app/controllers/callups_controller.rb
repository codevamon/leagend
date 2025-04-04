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
    return redirect_to root_path, alert: "Convocatoria no encontrada." unless callup&.pending?

    callup.update!(status: :accepted)

    unless callup.duel.present?
      flash[:notice] = "Te uniste correctamente. El duelo aún no ha sido creado."
      return redirect_back fallback_location: root_path
    end

    Lineup.find_or_create_by!(
      duel: callup.duel,
      user: current_user,
      teamable: callup.teamable
    )

    Notification.create!(
      recipient: callup.teamable.captain,
      sender: current_user,
      category: :callup,
      message: "#{current_user.slug} ha aceptado la convocatoria para el duelo.",
      notifiable: callup.duel
    )

    redirect_to duel_path(callup.duel_id), notice: "Has aceptado la convocatoria."
  end

  def reject
    callup = current_user.callups.find_by(id: params[:callup_id])
    return redirect_to notifications_path, alert: "Convocatoria no encontrada." unless callup&.pending?

    callup.update!(status: :rejected)

    Notification.create!(
      recipient: callup.teamable.captain,
      sender: current_user,
      category: :callup,
      message: "#{current_user.slug} ha rechazado la convocatoria.",
      notifiable: callup.duel
    )

    redirect_to notifications_path, alert: "Has rechazado la convocatoria."
  end

  private

    def set_team
      @team = Team.find(params[:team_id])
    end

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end
end
