class NotificationService
  def self.notify_duel_created(duel)
    # Notificar al equipo local
    notify_team(duel.home_team, {
      title: "Nuevo duelo creado",
      body: "Has creado un duelo para #{duel.starts_at.strftime('%d/%m/%Y %H:%M')}",
      data: { duel_id: duel.id }
    })

    # Si hay arena, notificar a equipos cercanos
    if duel.arena.present?
      notify_nearby_teams(duel)
    end
  end

  def self.notify_duel_started(duel)
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
    end
  end

  private

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
end 