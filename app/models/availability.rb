class Availability < ApplicationRecord
  belongs_to :availablable, polymorphic: true

  enum :status, {
    blocked: 0,    # No disponible (vacaciones, lesiones, etc.)
    available: 1   # Disponible
  }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_start
  validate :no_overlap_for_availablable

  before_create :generate_uuid

  after_commit :broadcast_calendar_update

  private

  def ends_after_start
    errors.add(:ends_at, "must be after start time") if starts_at && ends_at && ends_at <= starts_at
  end

  def no_overlap_for_availablable
    return unless availablable_id && availablable_type
    overlaps = Availability.where(availablable: availablable)
                           .where.not(id: id)
                           .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    errors.add(:base, "Availability overlaps with another entry") if overlaps.exists?
  end

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  def broadcast_calendar_update
    broadcast_replace_to(
      "calendar",
      partial: "shared/calendar_events",
      locals: { reservations: Reservation.all, availabilities: Availability.all },
      target: "calendar"
    )
  end
end
