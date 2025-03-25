class Lineup < ApplicationRecord
  belongs_to :duel
  belongs_to :teamable, polymorphic: true  # Puede ser Team o TeamMembership
  belongs_to :user

  # Validación para evitar duplicados por combinación
  validates :user_id, uniqueness: {
    scope: [:duel_id, :teamable_id, :teamable_type],
    message: "can only appear once per duel and team"
  }

  # UUID para la tabla si estás usando `t.string :id`
  before_create :generate_uuid

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
