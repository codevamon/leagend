class Result < ApplicationRecord
  belongs_to :duel
  belongs_to :team

  enum outcome: { win: 'win', loss: 'loss', draw: 'draw' }
end
