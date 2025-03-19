class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_joinable, only: [:create]

  def create
    @membership = Membership.new(
      user: current_user,
      joinable: @joinable,
      status: default_status,
      role: :member
    )
  
    if @membership.save
      puts "✅ Membresía creada correctamente con ID: #{@membership.id}"
  
      if @joinable.is_a?(Club)
        puts "🔔 Enviando notificación a los admins del club: #{@joinable.name}"
      end
  
      redirect_to @joinable, notice: membership_success_message
    else
      puts "❌ Error al crear membresía: #{@membership.errors.full_messages}"
      redirect_to @joinable, alert: "Could not process your request"
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