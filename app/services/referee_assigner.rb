# app/services/referee_assigner.rb
class RefereeAssigner
    def self.assign_to_duel(duel)
      available_referees = Referee.where(available: true)
      if available_referees.any?
        referee = available_referees.sample
        duel.update(referee: referee)
      else
        duel.update(referee: nil)
      end
    end
  end