class Callup < ApplicationRecord
  belongs_to :duel, optional: true
  belongs_to :user
  belongs_to :teamable, polymorphic: true  # Team o TeamMembership

  enum :status, { pending: 0, accepted: 1, rejected: 2 }

  validates :user_id, uniqueness: {
    scope: [:duel_id, :teamable_id, :teamable_type],
    message: "already called up for this duel in that team"
  }

  before_create :generate_uuid

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
