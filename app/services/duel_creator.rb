class DuelCreator
    def initialize(home_team, away_team, date, location, referee_id = nil)
      @home_team = home_team
      @away_team = away_team
      @date = date
      @location = location
      @referee_id = referee_id
    end
  
    def create_duel
      Duel.create!(
        home_team: @home_team,
        away_team: @away_team,
        start_date: @date,
        address: @location,
        referee_id: @referee_id,
        status: :pending # Estado inicial del duelo
      )
    end
end