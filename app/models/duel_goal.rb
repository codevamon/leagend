class DuelGoal < ApplicationRecord
  belongs_to :duel
  belongs_to :user
  belongs_to :team

  before_create :generate_uuid

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
