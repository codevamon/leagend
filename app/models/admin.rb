class Admin < ApplicationRecord
  belongs_to :user
  belongs_to :club, optional: true
  belongs_to :clan, optional: true
  before_create :generate_uuid

  enum :level, { editor: 0, admin: 1, king: 2, moderator: 3 }

  validates :level, presence: true

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
