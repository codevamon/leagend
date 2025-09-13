class Reservation < ApplicationRecord
  belongs_to :reservable, polymorphic: true
  belongs_to :payer, class_name: "User"
  belongs_to :receiver, class_name: "User"

  enum :status, {
    held: 0,        # Reserva tentativa (wizard)
    reserved: 1,    # Confirmada
    paid: 2,        # Pagada
    canceled: 3,    # Cancelada
    blocked: 4      # Bloqueo manual (feriados, mantenimientos, indisponibilidad)
  }, validate: true

  validates :starts_at, :ends_at, presence: true
  validate  :ends_after_start
  validate  :no_overlap_for_arena
  validate  :no_overlap_for_user
  validate  :no_overlap_for_referee
  validate  :only_owner_can_block

  before_validation :set_default_duration
  before_create :generate_uuid

  after_commit :broadcast_calendar_update

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

  def no_overlap_for_user
    return unless payer_id && %w[held reserved paid].include?(status)
    overlap = Reservation.where(payer_id: payer_id)
                         .where.not(id: id)
                         .where(status: %w[held reserved paid])
                         .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                         .exists?
    errors.add(:base, "El usuario ya tiene una reserva en este horario") if overlap
  end

  def no_overlap_for_referee
    return unless receiver_id && %w[held reserved paid].include?(status)
    overlap = Reservation.where(receiver_id: receiver_id)
                         .where.not(id: id)
                         .where(status: %w[held reserved paid])
                         .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                         .exists?
    errors.add(:base, "El referee ya tiene una reserva en este horario") if overlap
  end

  def set_default_duration
    self.ends_at ||= self.starts_at + 60.minutes if self.starts_at
  end

  def only_owner_can_block
    if status == "blocked" && reservable.is_a?(Arena)
      arena_owner = reservable.owner
      unless arena_owner&.level == "verified" && arena_owner.user_id == payer_id
        errors.add(:base, "Solo el propietario verificado puede bloquear esta arena")
      end
    end
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
