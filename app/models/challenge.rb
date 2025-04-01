class Challenge < ApplicationRecord
  belongs_to :challenger_duel,
  class_name: 'Duel',
  primary_key: :id,
  foreign_key: :challenger_duel_id

  belongs_to :challengee_duel,
    class_name: 'Duel',
    primary_key: :id,
    foreign_key: :challengee_duel_id

  enum :status, { pending: 'pending', accepted: 'accepted', rejected: 'rejected' }, default: :pending

  validates :challenger_duel_id, :challengee_duel_id, presence: true
end
