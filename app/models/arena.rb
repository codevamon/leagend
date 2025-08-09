class Arena < ApplicationRecord
  belongs_to :owner, class_name: "Owner", foreign_key: :owner_id
  has_many :reservations, as: :reservable, dependent: :destroy
  has_many :duels

  has_many_attached :photos
  has_many :business_hours, class_name: "ArenaBusinessHour", dependent: :destroy
  has_many :closures, class_name: "ArenaClosure", dependent: :destroy
  has_one :last_verification, -> { order(created_at: :desc) }, class_name: "ArenaVerification"

  enum :status, { unverified: "unverified", pending_review: "pending_review", verified: "verified" }, validate: true

  validates :name, :address, presence: true
  validate :photos_limit

  extend FriendlyId
  friendly_id :name, use: :slugged

  before_create :generate_uuid

  def available_between?(start_time, end_time)
    return false if closures.where("starts_at < ? AND ends_at > ?", end_time, start_time).exists?
    reservations.where("starts_at < ? AND ends_at > ?", end_time, start_time)
                .where(status: %w[held reserved paid]).none?
  end

  private

  def photos_limit
    return unless photos.attached?
    errors.add(:photos, "máximo 15 imágenes") if photos.attachments.size > 15
  end

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
