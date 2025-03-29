class Clan < ApplicationRecord
  belongs_to :king, class_name: 'User', foreign_key: 'user_id'
  has_many :admins, dependent: :destroy
  has_many :users, through: :admins

  has_many :memberships, as: :joinable, dependent: :destroy
  has_many :teams, as: :joinable, dependent: :destroy # ← 🔹 ESTA
  has_many :team_memberships, through: :teams

  has_one_attached :avatar

  validates :name, presence: true

  # Friendly ID
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  before_validation :set_uuid, on: :create
  before_validation :set_slug, on: :create
  after_create :create_creator_membership

  def moderators
    admins.where(level: :admin)
  end

  private

  def set_uuid
    self.id ||= SecureRandom.uuid
  end

  def set_slug
    self.slug = name.parameterize if slug.blank? || new_record?
  end

  def create_creator_membership
    memberships.create!(
      user: king,
      status: :approved,
      role: :king
    )
  end

  def slug_candidates
    [
      :name,
      [:name, SecureRandom.hex(4)]
    ]
  end
end
  