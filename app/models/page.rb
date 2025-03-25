class Page < ApplicationRecord
  before_create :generate_uuid
  before_validation :generate_slug, on: :create

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  private

    def generate_uuid
      self.id ||= SecureRandom.uuid
    end

    def generate_slug
      self.slug ||= title.parameterize if title.present?
    end
end
