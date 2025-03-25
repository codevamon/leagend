class Referee < ApplicationRecord
  belongs_to :user
  has_many :duels
  has_many :reservations, as: :reservable, dependent: :destroy

  validates :fee, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: true

  before_create :generate_uuid

  # Devuelve true si el referee está disponible en el rango dado
  def available_between?(start_time, end_time)
    reservations.where("start_time < ? AND end_time > ?", end_time, start_time).none?
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
