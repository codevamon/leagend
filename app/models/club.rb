class Club < ApplicationRecord
    belongs_to :king, class_name: 'User', foreign_key: 'user_id'
    has_many :admins, dependent: :destroy
    has_many :users, through: :admins
    has_many :memberships, as: :joinable, dependent: :destroy
    has_one_attached :avatar
  
    validates :name, presence: true
    validates :user_id, presence: true
  
    # Friendly ID
    extend FriendlyId
    friendly_id :slug_candidates, use: :slugged
  
    before_validation :set_uuid, on: :create
    before_validation :set_slug, on: :create
    after_create :create_king_membership
  
    def king_admin
        admins.find_by(level: :king) # Busca al admin con nivel "king"
    end

    private
    
      def set_uuid
        self.id ||= SecureRandom.uuid
      end
    
      def slug_candidates
        [
          :name,
          [:name, SecureRandom.hex(4)]
        ]
      end
    
      def set_slug
        self.slug = name.parameterize if slug.blank?
      end

      def create_king_membership
        memberships.create!(
          user: king,
          status: :approved,
          role: :king
        )
      end
  end
  