class DuelMerger
  def self.call(challenge)
    challenger = challenge.challenger_duel
    challengee = challenge.challengee_duel

    # Validaciones críticas
    return false unless valid_merge?(challenger, challengee)

    ActiveRecord::Base.transaction do
      # 1. Asignar away_team al challenger
      challenger.update!(away_team_id: challengee.home_team_id)

      # 2. Copiar callups del challengee al challenger (evitando duplicados)
      challengee.callups.each do |callup|
        next if challenger.callups.exists?(user: callup.user, teamable: challenger.away_team)
        
        Callup.create!(
          user: callup.user,
          teamable: challenger.away_team,
          duel: challenger,
          status: callup.status
        )
      end

      # 3. Copiar lineups del challengee al challenger (evitando duplicados)
      challengee.lineups.each do |lineup|
        next if challenger.lineups.exists?(user: lineup.user, teamable: challenger.away_team)
        
        Lineup.create!(
          user: lineup.user,
          teamable: challenger.away_team,
          duel: challenger
        )
      end

      # 4. Marcar challengee como merged y actualizar status del challenger
      challengee.update!(status: 'merged')
      challenger.update!(status: 'open') if challenger.status == 'pending'

      # 5. Notificar a los usuarios
      NotificationService.notify_duels_merged(challenger, challengee)
    end

    challenger
  rescue => e
    Rails.logger.error "Error en DuelMerger: #{e.message}"
    false
  end

  private

  def self.valid_merge?(challenger, challengee)
    return false if challenger.away_team_id.present?
    return false if challenger.status.in?(['finished', 'cancelled', 'merged'])
    return false if challengee.status.in?(['finished', 'cancelled', 'merged'])
    return false if challenger.starts_at != challengee.starts_at
    true
  end
end
