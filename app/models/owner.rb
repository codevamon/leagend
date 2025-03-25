class Owner < ApplicationRecord
  belongs_to :user
  has_many :arenas, foreign_key: :owner_id

  enum level: { basic: 0, verified: 1, pro: 2, admin: 3 }

  before_create :generate_uuid

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
