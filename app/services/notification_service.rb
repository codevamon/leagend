class NotificationService
  def self.notify_duel_created(duel)
<<<<<<< HEAD
    # Notificar al equipo local
    notify_team(duel.home_team, {
      title: "Nuevo duelo creado",
      body: "Has creado un duelo para #{duel.starts_at.strftime('%d/%m/%Y %H:%M')}",
      data: { duel_id: duel.id }
    })

    # Si hay arena, notificar a equipos cercanos
    if duel.arena.present?
      notify_nearby_teams(duel)
=======
    return unless duel.persisted?

    # Notificar al capitán del equipo local (solo si existe)
    notify_team_captain(duel.home_team, duel, "Has creado un nuevo duelo") if duel.home_team&.captain
    
    # Notificar a los jugadores convocados (solo si hay equipo)
    notify_team_players(duel.home_team, duel, "Has sido convocado a un nuevo duelo") if duel.home_team
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
>>>>>>> 7f45a488370116d2e378852178b09b3b9460e954
    end
  end

  def self.notify_duel_started(duel)
<<<<<<< HEAD
    # Notificar a todos los jugadores convocados
    duel.lineups.includes(:user).each do |lineup|
      notify_user(lineup.user, {
        title: "¡El duelo está por comenzar!",
        body: "Tu duelo en #{duel.arena&.name || 'la cancha'} comienza en 30 minutos",
        data: { duel_id: duel.id }
      })
    end
  end

  def self.notify_duel_finished(duel)
    # Notificar resultado a ambos equipos
    [duel.home_team, duel.away_team].each do |team|
      notify_team(team, {
        title: "Duelo finalizado",
        body: "El duelo ha terminado. #{duel.result&.outcome || 'Sin resultado registrado'}",
        data: { duel_id: duel.id }
      })
    end
  end

  def self.notify_duel_cancelled(duel)
    # Notificar cancelación a todos los involucrados
    duel.lineups.includes(:user).each do |lineup|
      notify_user(lineup.user, {
        title: "Duelo cancelado",
        body: "El duelo programado para #{duel.starts_at.strftime('%d/%m/%Y %H:%M')} ha sido cancelado",
        data: { duel_id: duel.id }
      })
    end
  end

  def self.notify_free_player_joined(duel, user)
    # Notificar a los capitanes que un jugador libre se unió
    [duel.home_team, duel.away_team].each do |team|
      if team.captain.present?
        notify_user(team.captain, {
          title: "Nuevo jugador unido",
          body: "#{user.name} se ha unido al duelo como jugador libre",
          data: { duel_id: duel.id }
        })
      end
=======
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
      notification = Notification.create!(
        recipient: callup.user,
        sender: sender,
        message: "Fuiste convocado a un duelo",
        category: :callup,
        notifiable: callup
      )
      Rails.logger.info "Notificación creada para #{callup.user.slug}"
>>>>>>> 7f45a488370116d2e378852178b09b3b9460e954
    end
  end

  private

<<<<<<< HEAD
    def self.notify_team(team, notification)
      team.users.each do |user|
        notify_user(user, notification)
      end
    end

    def self.notify_user(user, notification)
      # Aquí implementarías la lógica real de notificaciones
      # Por ejemplo, usando ActionCable, Firebase, etc.
      Rails.logger.info "Notificación para #{user.email}: #{notification[:title]} - #{notification[:body]}"
    end

    def self.notify_nearby_teams(duel)
      # Buscar equipos cercanos a la arena
      nearby_teams = Team.joins(:duels)
                        .where("duels.starts_at > ?", Time.current)
                        .where("duels.arena_id = ?", duel.arena_id)
                        .where("duels.id != ?", duel.id)
                        .distinct

      nearby_teams.each do |team|
        notify_team(team, {
          title: "Duelo disponible cerca",
          body: "Hay un duelo disponible en #{duel.arena.name} para #{duel.starts_at.strftime('%d/%m/%Y %H:%M')}",
          data: { duel_id: duel.id }
        })
      end
    end
=======
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
      next if team.captain && callup.user == team.captain

      Notification.create!(
        recipient: callup.user,
        sender: team.captain || callup.user, # Fallback si no hay captain
        message: message,
        category: :duel,
        notifiable: duel
      )
    end
  end
>>>>>>> 7f45a488370116d2e378852178b09b3b9460e954
end 