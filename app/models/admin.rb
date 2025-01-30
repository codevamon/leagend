class Admin < ApplicationRecord
  belongs_to :user
  belongs_to :club, optional: true
  belongs_to :clan, optional: true

  # Validaciones para asegurar que un Admin esté asociado a un Club o Clan, pero no a ambos
  validate :club_or_clan_present

  
  private

    def club_or_clan_present
      if club.blank? && clan.blank?
        errors.add(:base, "An Admin must be associated with either a Club or a Clan")
      elsif club.present? && clan.present?
        errors.add(:base, "An Admin cannot be associated with both a Club and a Clan")
      end
    end
end
