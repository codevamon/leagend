class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validate :only_one_leader_per_team


  private

    def only_one_leader_per_team
      if leader && TeamMembership.where(team_id: team_id, leader: true).where.not(id: id).exists?
        errors.add(:leader, "can only be one leader per team")
      end
    end
end
