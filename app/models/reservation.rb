class Reservation < ApplicationRecord
  belongs_to :reservable, polymorphic: true
  belongs_to :payer, class_name: "User"
  belongs_to :receiver, class_name: "User"

  before_create :generate_uuid

  validates :start_time, :end_time, presence: true
  validates :price_per_hour, :total_price, numericality: { greater_than_or_equal_to: 0 }

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end
end
