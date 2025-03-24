class ClubsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_club, only: [:show, :edit, :update, :destroy, :join, :approve_member]

  def index
    @clubs = Club.all
  end

  def show
    @members = @club.users

    if user_signed_in?
      @membership = @club.memberships.find_by(user: current_user)
      @is_admin = @club.admins.exists?(user_id: current_user.id)
    end
    # @pending_memberships = @club.memberships.pending
  end

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params.except(:avatar)) # No incluir avatar al inicio
    @club.king = current_user
  
    if @club.save
      # Adjuntar la imagen solo después de que el club ha sido guardado
      @club.avatar.attach(params[:club][:avatar]) if params[:club][:avatar].present?
  
      # Crear el Admin correctamente asignando UUIDs
      Admin.create!(
        user_id: current_user.id,
        club_id: @club.id,
        level: 2
      )
      
      redirect_to @club, notice: 'Club creado exitosamente.'
    else
      flash.now[:alert] = @club.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
  end

  def update
    if @club.update(club_params.except(:avatar))
      if params[:club][:avatar].present?
        # Elimina la imagen anterior si existe antes de adjuntar la nueva
        @club.avatar.purge_later if @club.avatar.attached?
  
        @club.avatar.attach(params[:club][:avatar])
      end
      redirect_to @club, notice: "Club actualizado correctamente."
    else
      render :edit
    end
  end
  

  def destroy
    @club.destroy
    redirect_to clubs_url, notice: 'Club eliminado correctamente.'
  end

  # Acción para que un usuario solicite unirse a un club
  def join
    if @club.memberships.where(user: current_user).exists?
      redirect_to @club, alert: 'Ya eres miembro de este club.'
    else
      membership = Membership.create(user: current_user, joinable: @club, status: :pending, role: :member)
      @club.admins.each do |admin|
        Notification.create!(
          recipient: admin.user,
          sender: current_user,
          category: :club,
          message: "#{current_user.slug} solicitó unirse a #{@club.name}",
          notifiable: membership
        )
      end
      redirect_to @club, notice: 'Tu solicitud para unirte al club ha sido enviada.'
    end
  end

  # Acción para que un admin apruebe a un usuario en un club
  def approve_member
    membership = @club.memberships.find(params[:membership_id])
    if membership.update(status: :approved)
      redirect_to @club, notice: 'Miembro aprobado.'
    else
      redirect_to @club, alert: 'No se pudo aprobar al miembro.'
    end
  end

  private


  def set_club
    @club = Club.friendly.find_by(slug: params[:id])
    
    unless @club
      redirect_to clubs_path, alert: "No se encontró el club."
      return
    end
  end

  def club_params
    params.require(:club).permit(:name, :description, :address, :avatar)
  end
end
