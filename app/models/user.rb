class User < ApplicationRecord
  # Friendly ID
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  # Callbacks
  before_validation :set_uuid, on: :create
  before_save :set_avatar_from_url, if: -> { image_url.present? && avatar.blank? }

  # Validations
  validates :id, presence: true
  validates :slug, presence: true, uniqueness: true, length: { maximum: 50 }, format: { without: /\s/, message: "cannot contain spaces" }
  validates :phone_number, format: { with: /\A\+\d{1,3}\d{7,15}\z/, message: "must be a valid phone number" }, allow_blank: true

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
         
  attr_writer :login
  attr_accessor :image_url

  # Medias
  has_one_attached :avatar
  has_one_attached :coverpage
  
  # Relaciones como árbitro
  has_one :referee
  has_many :refereed_duels, through: :referee, source: :duels

  # Otras relaciones
  has_many :admins
  has_many :clubs, through: :admins
  has_many :clans, through: :admins
  
  # Relaciones como jugador
  has_many :team_memberships
  has_many :teams, through: :team_memberships
  has_many :duels, through: :teams
  
  # Método para verificar si el usuario es líder de algún equipo
  def leader?
    team_memberships.exists?(leader: true)
  end

  # Método para obtener los equipos donde el usuario es líder
  def leading_teams
    teams.joins(:team_memberships).where(team_memberships: { leader: true })
  end
  
  # Métodos para estadísticas unificadas
  def total_duels
    duels.count
  end

  def wins
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: 'win' }).count
  end

  def losses
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: 'loss' }).count
  end

  def draws
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: 'draw' }).count
  end


  private

    def set_uuid
      self.id ||= SecureRandom.uuid
    end

    def slug_candidates
      [
        :lastname,
        [:lastname, :firstname],
        [:lastname, :firstname, SecureRandom.hex(4)]
      ]
    end

    def set_avatar_from_url
      file = URI.open(image_url)
      self.avatar.attach(io: file, filename: File.basename(file.path), content_type: file.content_type)
    rescue StandardError => e
      errors.add(:avatar, "could not be uploaded from URL: #{e.message}")
    end


end
