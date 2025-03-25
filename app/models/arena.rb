class Arena < ApplicationRecord
  belongs_to :owner
  has_many :reservations, as: :reservable, dependent: :destroy

  before_create :generate_uuid

  extend FriendlyId
  friendly_id :name, use: :slugged

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
