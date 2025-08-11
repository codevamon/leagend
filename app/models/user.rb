require "open-uri"

class User < ApplicationRecord
  # Devise
  attr_writer :login
  attr_accessor :image_url

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # FriendlyId
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  def should_generate_new_friendly_id?
    slug.blank?  # genera solo si está vacío
  end

  # Callbacks
  before_validation :set_uuid, on: :create
  before_validation :ensure_unique_slug, on: :create   # <-- asegura unicidad
  before_save :set_avatar_from_url, if: -> { image_url.present? && avatar.blank? }

  # Validations
  validates :id, presence: true
  validates :slug, presence: true, uniqueness: true, length: { maximum: 50 }, format: { without: /\s/, message: "cannot contain spaces" }

  # Medias
  has_one_attached :avatar
  has_one_attached :coverpage

  # Relaciones
  has_one :owner
  has_one :referee
  has_many :owned_clubs, class_name: "Club", foreign_key: "user_id", dependent: :destroy
  has_many :refereed_duels, through: :referee, source: :duels
  has_many :admins, dependent: :destroy
  has_many :clubs, through: :admins
  has_many :clans, through: :admins
  has_many :memberships, dependent: :destroy
  has_many :team_memberships
  has_many :teams, through: :team_memberships
  has_many :duels, through: :teams
  has_many :callups, dependent: :destroy
  has_many :called_up_teams, through: :callups, source: :teamable
  has_many :notifications, as: :recipient
  has_many :owned_teams, class_name: "Team", foreign_key: "leader_id"
  has_many :stats
  has_many :sent_reservations, class_name: "Reservation", foreign_key: :payer_id, dependent: :nullify
  has_many :received_reservations, class_name: "Reservation", foreign_key: :receiver_id, dependent: :nullify

  # Métodos de líder
  def leader?
    team_memberships.exists?(leader: true)
  end

  def leading_teams
    teams.joins(:team_memberships).where(team_memberships: { leader: true })
  end

  # Estadísticas
  def total_duels
    duels.count
  end

  def wins 
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: "win" }).count
  end

  def losses
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: "loss" }).count
  end

  def draws
    duels.joins(:results).where(results: { team_id: teams.ids, outcome: "draw" }).count
  end

  # Avatar URL helper
  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      "/default_avatar.png"
    end
  end

  # Nombre mostrable
  def display_name
    n = [firstname, lastname].compact.join(" ").strip
    n.presence || slug.presence || email
  end

  # ================= Omniauth =================
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    unless user
      user = find_or_initialize_by(email: auth.info.email)
      user.provider = auth.provider
      user.uid      = auth.uid
    end

    user.firstname ||= auth.info.first_name || auth.info.name&.split&.first
    user.lastname  ||= auth.info.last_name  || auth.info.name&.split&.last

    # Fuerza generación via ensure_unique_slug/FriendlyId en persistencia
    user.slug = nil if user.slug.blank?

    # Teléfono dummy si falta o colisiona
    if user.phone_number.blank? || User.exists?(phone_number: user.phone_number)
      user.phone_number = "+000000#{rand(1000..9999)}"
    end

    user.password = Devise.friendly_token[0, 20] if user.encrypted_password.blank?
    user.save!  # ya no chocará por slug

    user.attach_google_avatar(auth)
    user
  end

  # Descarga y adjunta avatar de Google si no existe
  def attach_google_avatar(auth)
    return if avatar.attached?
    url = auth.info.image.to_s
    return if url.blank?

    # Normaliza tamaño (Google) p.ej. ...=s96-c -> s256-c
    url = url.gsub(/=s\d+-c\z/, '=s256-c')

    file = URI.open(url)
    file.rewind
    content_type = file.content_type.presence || "image/jpeg"
    ext = content_type.split("/").last

    avatar.attach(io: file, filename: "avatar-#{id}.#{ext}", content_type: content_type)
  rescue => e
    Rails.logger.warn("Avatar Google no adjuntado: #{e.class} #{e.message}")
  end

  private

  def set_uuid
    self.id ||= SecureRandom.uuid
  end

  # Candidatos FriendlyId (se usa solo si slug está vacío)
  def slug_candidates
    [
      :lastname,
      [:lastname, :firstname]
    ]
  end

  # Genera slug base y lo hace único: base, base-1a2b, ...
  def ensure_unique_slug
    base = (slug.presence ||
            [firstname, lastname].compact.join("-").presence ||
            email.to_s.split("@").first).to_s.parameterize.presence || "u"

    self.slug = unique_slug_for(base)
  end

  def unique_slug_for(base)
    try = base
    0.upto(20) do
      return try unless User.where.not(id: id).exists?(slug: try)
      try = "#{base}-#{SecureRandom.alphanumeric(4).downcase}"
    end
    "#{base}-#{SecureRandom.alphanumeric(8).downcase}"
  end

  def set_avatar_from_url
    file = URI.open(image_url)
    self.avatar.attach(io: file, filename: File.basename(file.path), content_type: file.content_type)
  rescue StandardError => e
    errors.add(:avatar, "could not be uploaded from URL: #{e.message}")
  end
end
