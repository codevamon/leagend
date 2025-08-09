class ArenaVerificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_arena, only: [:new, :create]
  before_action :set_verification, only: [:approve, :reject]
  before_action :authorize_admin!, only: [:approve, :reject]

  def new
    @verification = ArenaVerification.new
  end

  def create
    service = ArenaVerificationService.new
    
    begin
      @verification = service.submit(
        arena: @arena,
        user: current_user,
        method: verification_params[:payout_method],
        payload: verification_params[:payout_payload],
        documents: verification_params[:documents] || []
      )
      
      redirect_to @arena, notice: 'Solicitud de verificación enviada exitosamente.'
    rescue => e
      @verification = ArenaVerification.new(verification_params)
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    service = ArenaVerificationService.new
    service.approve(verification: @verification, admin_user: current_user)
    
    redirect_to admin_verifications_path, notice: 'Arena verificada exitosamente.'
  end

  def reject
    service = ArenaVerificationService.new
    service.reject(verification: @verification, reason: params[:reason])
    
    redirect_to admin_verifications_path, notice: 'Verificación rechazada.'
  end

  private

  def set_arena
    @arena = Arena.friendly.find(params[:arena_id])
    authorize_owner!(@arena)
  end

  def set_verification
    @verification = ArenaVerification.find(params[:id])
  end

  def verification_params
    params.require(:arena_verification).permit(
      :payout_method, :payout_payload, documents: []
    )
  end

  def authorize_owner!(arena)
    unless arena.owner.user_id == current_user.id
      redirect_to arenas_path, alert: 'No tienes permisos para esta arena.'
    end
  end

  def authorize_admin!
    unless current_user.admin?
      redirect_to root_path, alert: 'Acceso denegado.'
    end
  end
end
