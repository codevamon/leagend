class Notification < ApplicationRecord
  belongs_to :recipient, polymorphic: true
  belongs_to :sender, polymorphic: true
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :category, { callup: 0, duel: 1, club: 2, team: 3, general: 4 }
  enum :status, { unread: 0, read: 1 }

  validates :message, presence: true

  before_create :generate_uuid
  after_create :send_notification

  def actionable_by?(user)
    return false unless recipient == user
    return false unless unread?
    return false unless actionable_type?
    return false if responded? # 🔥 Clave para ocultar botones si ya respondió
  
    true
  end

  def actionable_type?
    (category == "club" && notifiable.is_a?(Membership)) ||
    (category == "callup" && notifiable.is_a?(Callup))
  end

  def responded?
    case category
    when "club"
      notifiable.is_a?(Membership) && !notifiable.pending?
    when "callup"
      notifiable.is_a?(Callup) && !notifiable.pending?
    else
      false
    end
  end

  # ✅ EL MÉTODO CLAVE
  def ready_to_be_marked_read?
    return true if read?
  
    # Informativas: Club, Duel, Team, General (nunca requieren acción)
    return true unless actionable_type?
  
    # Accionables: Solo si ya fueron respondidas
    responded?
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  def send_notification
    # Placeholder para lógica adicional
  end
end
