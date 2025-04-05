class DuelMerger
  def self.call(challenge)
    challenger = challenge.challenger_duel
    challengee = challenge.challengee_duel

    # asignar away_team
    challenger.update!(away_team_id: challengee.home_team_id)

    # copiar Callups del challengee al challenger
    challengee.callups.each do |callup|
      Callup.create!(
        user: callup.user,
        team: challenger.away_team,
        duel: challenger
      )
    end

    # copiar Lineups del challengee al challenger
    challengee.lineups.each do |lineup|
      Lineup.create!(
        user: lineup.user,
        team: challenger.away_team,
        duel: challenger
      )
    end

    # marcar duel challengee como merged (o archivado)
    challengee.update!(status: 'merged')

    challenger
  end
end
