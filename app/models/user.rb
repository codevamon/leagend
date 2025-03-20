require 'open-uri'

class User < ApplicationRecord
  # Devise modules
  attr_writer :login
  attr_accessor :image_url

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]  # 👈 ESTA LÍNEA ES CLAVE


  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      # Asignar datos básicos de Google
      user.email       = auth.info.email
      user.firstname   = auth.info.first_name  || auth.info.name&.split&.first
      user.lastname    = auth.info.last_name   || auth.info.name&.split&.last

      # Generar slug si está en blanco
      if user.slug.blank?
        slug_candidate = [user.firstname, user.lastname].compact.join("-").parameterize
        user.slug      = slug_candidate.presence || "google-#{SecureRandom.hex(4)}"
      end

      # Si tu callback set_avatar_from_url espera user.image_url
      if auth.info.image.present?
        user.image_url = auth.info.image
      end

      # Campos extra (country, city, neighborhood):
      # Google no los da por defecto, puedes obtenerlos si configuras scopes avanzados.
      # Suponiendo que estuvieran en auth.extra.raw_info:
      # user.country      = auth.extra.raw_info.country      if auth.extra&.raw_info&.country
      # user.city         = auth.extra.raw_info.city         if auth.extra&.raw_info&.city
      # user.neighborhood = auth.extra.raw_info.neighborhood if auth.extra&.raw_info&.neighborhood

      # Evitar error con phone_number NOT NULL, asignando placeholder válido
      user.phone_number ||= "+0000000000"

      # Generar password si no existe
      user.password = Devise.friendly_token[0,20] if user.encrypted_password.blank?

      user.save
    end
  end
          

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

  

  # def self.from_omniauth(auth)
  #   where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
  #     user.email = auth.info.email
  #     user.password = Devise.friendly_token[0, 20]
  #     user.name = auth.info.name # si tienes un campo 'name'
  #   end
  # end


  # Medias
  has_one_attached :avatar
  has_one_attached :coverpage
  
  # Relaciones como árbitro
  has_one :referee
  has_many :owned_clubs, class_name: 'Club', foreign_key: 'user_id', dependent: :destroy
  has_many :refereed_duels, through: :referee, source: :duels
  has_many :admins, dependent: :destroy
  has_many :clubs, through: :admins
  has_many :clans, through: :admins
  has_many :memberships, dependent: :destroy
  has_many :team_memberships
  has_many :teams, through: :team_memberships
  has_many :duels, through: :teams
  has_many :callups, dependent: :destroy
  has_many :called_up_teams, through: :callups, source: :team
  has_many :notifications, as: :recipient
  has_many :owned_teams, class_name: 'Team', foreign_key: 'leader_id'
  has_many :stats
  
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


  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      "/default_avatar.png"
    end
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
