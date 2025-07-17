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
    callup = current_user.callups.find_by(id: params[:id])
    return redirect_to root_path, alert: "Convocatoria no encontrada." unless callup&.pending?
  
    ActiveRecord::Base.transaction do
      # ✅ Aceptar la convocatoria actual
      callup.update!(status: :accepted)
  
      # 🚫 Rechazar otras convocatorias del mismo duelo
      current_user.callups
                  .where(duel_id: callup.duel_id, status: :pending)
                  .where.not(id: callup.id)
                  .update_all(status: :rejected)
  
      # ✅ Asegurar que el callup tenga duelo
      if callup.duel.nil?
        duel = Duel.find_by(home_team: callup.teamable)
        callup.update!(duel: duel) if duel
      end
  
      # ✅ Crear lineup
      if callup.duel.present?
        Lineup.find_or_create_by!(
          duel: callup.duel,
          user: current_user,
          teamable: callup.teamable
        )
      end
  
      # 🔔 Notificar al capitán del equipo
      if callup.teamable.respond_to?(:captain) && callup.teamable.captain
        Notification.create!(
          recipient: callup.teamable.captain,
          sender: current_user,
          category: :callup,
          message: "#{current_user.slug} ha aceptado la convocatoria para el duelo.",
          notifiable: callup.duel || callup.teamable
        )
      end
    end

    team = callup.teamable
    duel = callup.duel

          # Verifica si todos los callups están aceptados
      if duel.present?
        accepted_count = Lineup.where(duel: duel, teamable: team).count
        expected_count = team.callups.where(duel: duel).count

        if accepted_count > 0 && accepted_count == expected_count
          team.update!(temporary: false, status: :confirmed)
        end
      end

    @callup = callup
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to duel_path(callup.duel_id), notice: "Has aceptado la convocatoria." }
    end
  end

  def reject
    callup = current_user.callups.find_by(id: params[:id])
    return redirect_to notifications_path, alert: "Convocatoria no encontrada." unless callup&.pending?

    callup.update!(status: :rejected)

    if callup.teamable.respond_to?(:captain) && callup.teamable.captain
      Notification.create!(
        recipient: callup.teamable.captain,
        sender: current_user,
        category: :callup,
        message: "#{current_user.slug} ha rechazado la convocatoria.",
        notifiable: callup.duel || callup.teamable
      )
    end

    @callup = callup

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path, alert: "Has rechazado la convocatoria." }
    end
  end

  private

    def set_team
      @team = Team.find(params[:team_id])
    end

    def set_duel
      @duel = Duel.find(params[:duel_id])
    end
end
