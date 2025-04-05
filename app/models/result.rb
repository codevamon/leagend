class Result < ApplicationRecord
  belongs_to :referee, optional: true
  belongs_to :best_player, class_name: "User", optional: true
  belongs_to :referee, class_name: 'User', optional: true
  belongs_to :home_teamable, polymorphic: true
  belongs_to :away_teamable, polymorphic: true

  enum :outcome, { win: 0, loss: 1, draw: 2 }

  before_create :generate_uuid

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
