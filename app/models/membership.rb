class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :joinable, polymorphic: true # Puede ser Club o Clan

  # Enums
  enum status: { pending: 0, approved: 1 }
  enum role: { admin: 0, member: 1 }

  # Validación para evitar membresías duplicadas
  validates :user_id, uniqueness: { 
    scope: [:joinable_type, :joinable_id], 
    message: "already has a membership for this entity" 
  }
end
