class ArenaVerification < ApplicationRecord
  belongs_to :arena, foreign_key: :arena_id
  belongs_to :submitted_by, class_name: "User"

  enum :status, { draft: "draft", submitted: "submitted", approved: "approved", rejected: "rejected" }, validate: true
  has_many_attached :documents

  before_create { self.id ||= SecureRandom.uuid }
end
