class DestroyExpiredTeamsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    Team.where(temporary: true).where("expires_at <= ?", Time.current).destroy_all
  end
end
