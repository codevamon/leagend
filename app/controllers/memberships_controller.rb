# app/controllers/memberships_controller.rb
class MembershipsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_joinable, only: [:create]
  
    # POST /memberships
    def create
      @membership = Membership.new(
        user: current_user,
        joinable: @joinable,
        status: default_status,
        role: :member
      )
  
      if @membership.save
        redirect_to @joinable, notice: membership_success_message
      else
        redirect_to @joinable, alert: "Could not process your request"
      end
    end
  
    # PATCH /memberships/:id/approve
    def approve
      @membership = Membership.find(params[:id])
      if @membership.update(status: :approved)
        Notification.create(
          recipient: @membership.user,
          sender: @membership.joinable,
          category: :membership,
          message: "Your membership to #{@membership.joinable.name} has been approved!"
        )
        redirect_back fallback_location: @membership.joinable, notice: "Membership approved"
      else
        redirect_back fallback_location: @membership.joinable, alert: "Approval failed"
      end
    end
  
    private
  
    def set_joinable
      if params[:club_id]
        @joinable = Club.find(params[:club_id])
      elsif params[:clan_id]
        @joinable = Clan.find(params[:clan_id])
      end
      redirect_to root_path, alert: "Invalid entity" unless @joinable
    end
  
    def default_status
      @joinable.is_a?(Clan) ? :approved : :pending
    end
  
    def membership_success_message
      @joinable.is_a?(Clan) ? "Successfully joined clan!" : "Join request submitted for approval"
    end
  end