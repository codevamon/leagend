class Reservation < ApplicationRecord
  belongs_to :reservable, polymorphic: true
  belongs_to :payer, class_name: "User"
  belongs_to :receiver, class_name: "User"

  enum :status, { held: "held", reserved: "reserved", paid: "paid", canceled: "canceled" }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate  :ends_after_start
  validate  :no_overlap_for_arena

  before_create :generate_uuid

  private

  def ends_after_start
    errors.add(:ends_at, "debe ser mayor a starts_at") if starts_at && ends_at && ends_at <= starts_at
  end

  def no_overlap_for_arena
    return unless reservable_type == "Arena" && %w[held reserved paid].include?(status)
    overlap = Reservation.where(reservable_type: "Arena", reservable_id: reservable_id)
                         .where.not(id: id)
                         .where(status: %w[held reserved paid])
                         .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                         .exists?
    errors.add(:base, "El horario ya está reservado") if overlap
  end

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
