class ArenaBusinessHour < ApplicationRecord
  belongs_to :arena, foreign_key: :arena_id
  validates :weekday, inclusion: { in: 0..6 }
  validates :opens_at, :closes_at, presence: true, unless: :closed?
  validate  :range_valid

  before_create { self.id ||= SecureRandom.uuid }

  private
  def range_valid
    return if closed?
    errors.add(:base, "Horario inválido") if opens_at >= closes_at
  end
end
