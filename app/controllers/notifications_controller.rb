class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:update]

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def update
    case
    when params[:approve]
      process_membership_request(approved: true)
    when params[:reject]
      process_membership_request(approved: false)
    else
      @notification.update!(status: :read)
      redirect_to notifications_path, notice: "Notificación marcada como leída"
    end
  end

  def mark_all_read
    current_user.notifications.each do |notification|
      if notification.ready_to_be_marked_read?
        notification.update!(status: :read)
      end
    end

    redirect_to notifications_path, notice: "Notificaciones actualizadas"
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def process_membership_request(approved:)
    membership = Membership.find_by(id: @notification.notifiable_id)

    unless membership&.pending?
      redirect_to notifications_path, alert: "La solicitud ya fue procesada" and return
    end

    if approved
      membership.update!(status: :approved)
      notify_user(membership.user, membership.joinable, "Tu solicitud fue aprobada", :club)
    else
      membership.update!(status: :rejected)
      notify_user(membership.user, membership.joinable, "Tu solicitud fue rechazada", :club)
    end

    @notification.update!(status: :read)
    redirect_to notifications_path, notice: "Solicitud procesada correctamente"
  end

  def notify_user(user, joinable, message, category)
    Notification.create!(
      recipient: user,
      sender: joinable,
      category: category,
      message: message,
      notifiable: joinable
    )
  end
end
