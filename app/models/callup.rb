class Callup < ApplicationRecord
    belongs_to :team
    belongs_to :user
    belongs_to :duel
  
    enum status: { pending: 0, accepted: 1, rejected: 2 }
  
    validates :user_id, uniqueness: { scope: [:team_id, :duel_id], message: "User has already been called up for this duel." }
  
    after_create :send_notification
  
    private
  
    def send_notification
      Notification.create(
        recipient: user,
        sender: team.club || team.clan, # El club o clan que convoca
        category: :Callups,
        action: :Callup,
        message: "You have been called up for a duel by #{team.name}."
      )
    end
end
