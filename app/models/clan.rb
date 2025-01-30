class Clan < ApplicationRecord
    has_many :admins
    has_many :users, through: :admins
    has_many :teams
    has_many :team_memberships, through: :teams
end
