class ArenaClosure < ApplicationRecord
  belongs_to :arena, foreign_key: :arena_id
  validates :starts_at, :ends_at, presence: true
  validate  :range_valid

  before_create { self.id ||= SecureRandom.uuid }

  private
  def range_valid
    errors.add(:base, "Rango inválido") if starts_at >= ends_at
  end
end
