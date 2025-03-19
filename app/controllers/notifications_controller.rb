class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:update]
  def index
    @notifications = current_user.notifications.unread
    render json: @notifications
  end

  def update
    if @notification.category == "club"
      process_membership_request
    else
      @notification.update!(status: :read)
      render json: { message: "Notification marked as read" }, status: :ok
    end
  end


  
  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def process_membership_request
    membership = Membership.find_by(id: @notification.notifiable_id)

    unless membership&.pending?
      return render json: { message: "Request already processed" }, status: :unprocessable_entity
    end

    if params[:approve] == "true"
      membership.update!(status: :approved)
      notify_user(membership.user, membership.joinable, "Your membership request was approved!", :membership_approved)
    else
      membership.destroy
      notify_user(membership.user, membership.joinable, "Your membership request was denied.", :membership_rejected)
    end

    @notification.update!(status: :read)
    render json: { message: "Membership request processed" }, status: :ok
  end

  def notify_user(user, joinable, message, category)
    Notification.create!(
      recipient: user,
      sender: joinable,
      category: category,
      message: message
    )
  end
end
