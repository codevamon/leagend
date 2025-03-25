class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :club, optional: true
  belongs_to :clan, optional: true
  belongs_to :captain, class_name: 'User', optional: true

  before_create :generate_uuid

  validate :only_one_leader_per_team

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end

  def only_one_leader_per_team
    return unless leader?

    if self.class.where(club_id: club_id, clan_id: clan_id, leader: true).where.not(id: id).exists?
      errors.add(:leader, "can only be one leader per temporary team")
    end
  end
end
