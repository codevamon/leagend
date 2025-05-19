class NotificationService
  def self.notify_duel_created(duel)
    return unless duel.persisted?

    # Notificar al capitán del equipo local
    notify_team_captain(duel.home_team, duel, "Has creado un nuevo duelo")
    
    # Notificar a los jugadores convocados
    notify_team_players(duel.home_team, duel, "Has sido convocado a un nuevo duelo")
  end

  def self.notify_duel_updated(duel)
    return unless duel.saved_change_to_status?

    case duel.status
    when 'started'
      notify_duel_started(duel)
    when 'finished'
      notify_duel_finished(duel)
    when 'cancelled'
      notify_duel_cancelled(duel)
    end
  end

  def self.notify_duel_started(duel)
    message = "El duelo ha comenzado"
    notify_team_players(duel.home_team, duel, message)
    notify_team_players(duel.away_team, duel, message) if duel.away_team
  end

  def self.notify_duel_finished(duel)
    message = "El duelo ha finalizado"
    notify_team_players(duel.home_team, duel, message)
    notify_team_players(duel.away_team, duel, message) if duel.away_team
  end

  def self.notify_duel_cancelled(duel)
    message = "El duelo ha sido cancelado"
    notify_team_players(duel.home_team, duel, message)
    notify_team_players(duel.away_team, duel, message) if duel.away_team
  end

  def self.notify_callup(callup, sender)
    return if callup.user == sender

    unless Notification.exists?(recipient: callup.user, notifiable: callup, category: :callup)
      Notification.create!(
        recipient: callup.user,
        sender: sender,
        message: "Fuiste convocado a un duelo",
        category: :callup,
        notifiable: callup
      )
    end
  end

  private

  def self.notify_team_captain(team, duel, message)
    return unless team.captain

    Notification.create!(
      recipient: team.captain,
      sender: team.captain,
      message: message,
      category: :duel,
      notifiable: duel
    )
  end

  def self.notify_team_players(team, duel, message)
    return unless team

    team.callups.includes(:user).each do |callup|
      next if callup.user == team.captain

      Notification.create!(
        recipient: callup.user,
        sender: team.captain,
        message: message,
        category: :duel,
        notifiable: duel
      )
    end
  end
end 