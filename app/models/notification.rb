class Notification < ApplicationRecord
    belongs_to :recipient, polymorphic: true
    belongs_to :sender, polymorphic: true
  
    enum :category, { callup: 0, duel: 1, club: 2, team: 3, general: 4 }
    enum :status, { unread: 0, read: 1 }
  
    validates :message, presence: true
  
    after_create :send_notification
  
    private
  
    def send_notification
      # Aquí puedes agregar lógica para enviar notificaciones por correo electrónico, websockets, etc.
      # Por ejemplo:
      # NotificationMailer.notify_user(self).deliver_later
    end
end