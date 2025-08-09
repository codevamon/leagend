class Team < ApplicationRecord
  belongs_to :club, optional: true
  belongs_to :clan, optional: true
  belongs_to :joinable, polymorphic: true, optional: true
  belongs_to :captain, class_name: 'User', foreign_key: 'captain_id', optional: true

  has_many :callups, as: :teamable, dependent: :destroy
  has_many :called_up_users, through: :callups, source: :user

  has_many :home_duels, class_name: 'Duel', foreign_key: 'home_team_id'
  has_many :away_duels, class_name: 'Duel', foreign_key: 'away_team_id'

  has_many :results, ->(team) {
    unscope(where: :team_id).where("home_team_id = :id OR away_team_id = :id", id: team.id)
  }, class_name: 'Result'

  # Scopes
  scope :active, -> { where(temporary: false) }
  scope :temporary, -> { where(temporary: true) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :not_expired, -> { where('expires_at > ? OR expires_at IS NULL', Time.current) }

  before_create :generate_uuid
  before_create :set_expiration_if_temporary

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

  def temporary?
    temporary == true
  end

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
    def set_expiration_if_temporary
      if temporary? && expires_at.blank?
        self.expires_at = 3.weeks.from_now
      end
    end
end
