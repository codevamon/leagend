class Challenge < ApplicationRecord
  validates :challenger_duel_id, :challengee_duel_id, presence: true
  validates :challenger_duel_id, uniqueness: { scope: :challengee_duel_id, message: "ya se ha enviado un reto para este duelo." }
  
  belongs_to :challenger_duel,
    class_name: 'Duel',
    primary_key: :id,
    foreign_key: :challenger_duel_id

  belongs_to :challengee_duel,
    class_name: 'Duel',
    primary_key: :id,
    foreign_key: :challengee_duel_id

  enum :status, { pending: 'pending', accepted: 'accepted', rejected: 'rejected' }, default: :pending

  

end
