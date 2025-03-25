class Team < ApplicationRecord
  belongs_to :club, optional: true
  belongs_to :clan, optional: true
  belongs_to :captain, class_name: 'User', optional: true

  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships

  has_many :home_duels, class_name: 'Duel', foreign_key: 'home_team_id'
  has_many :away_duels, class_name: 'Duel', foreign_key: 'away_team_id'

  has_many :callups, dependent: :destroy
  has_many :called_up_users, through: :callups, source: :user

  has_many :results, ->(team) {
    unscope(where: :team_id).where("home_team_id = :id OR away_team_id = :id", id: team.id)
  }, class_name: 'Result'

  before_create :generate_uuid

  def duels
    Duel.where("home_team_id = ? OR away_team_id = ?", id, id)
  end

  def wins
    results.where(outcome: :win).count
  end

  def losses
    results.where(outcome: :loss).count
  end

  def draws
    results.where(outcome: :draw).count
  end

  def leader
    team_memberships.find_by(leader: true)&.user
  end

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
