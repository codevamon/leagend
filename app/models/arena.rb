class Arena < ApplicationRecord
  belongs_to :owner, class_name: "Owner", foreign_key: :owner_id
  has_many :reservations, as: :reservable, dependent: :destroy
  has_many :duels

  before_create :generate_uuid

  extend FriendlyId
  friendly_id :name, use: :slugged

  def available_between?(start_time, end_time)
    duels.where("starts_at < ? AND ends_at > ?", end_time, start_time).none?
  end

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
