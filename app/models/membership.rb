class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :joinable, polymorphic: true # Puede ser Club o Clan

  # Enums
  enum :status, { pending: 0, approved: 1 }
  enum :role, { admin: 0, member: 1 }

  # Validación para evitar membresías duplicadas
  validates :user_id, uniqueness: { 
    scope: [:joinable_type, :joinable_id], 
    message: "already has a membership for this entity" 
  }


  
  after_create :notify_admins, if: -> { joinable.is_a?(Club) }

  private

  def notify_admins
    admins = joinable.admins.where.not(level: 0) # Excluye a los 'editors'
    
    return if admins.empty? # No hay admins, no se envía notificación

    admins.each do |admin|
      Notification.create!(
        recipient: admin.user,  
        recipient_type: "User",
        sender: joinable,
        sender_type: "Club",
        category: :club,
        message: "#{user.slug} requested to join #{joinable.name}"
      )
    end
  end
end
