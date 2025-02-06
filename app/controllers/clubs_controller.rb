class ClubsController < ApplicationController
    before_action :set_club, only: [:show, :edit, :update, :destroy, :join, :approve_member]
    before_action :authenticate_user!, except: [:index, :show]
  
    # Listar todos los clubs
    def index
      @clubs = Club.all
    end
  
    # Mostrar un club específico
    def show
      @members = @club.users
      @club = Club.find(params[:id])
      @pending_memberships = @club.memberships.pending
      @pending_members = @club.memberships.where(status: :pending)
      @pending_memberships = @club.memberships.pending
    end
  
    # Formulario para crear un nuevo club
    def new
      @club = Club.new
    end
  
    # Crear un nuevo club
    def create
      @club = Club.new(club_params)
      @club.user = current_user # El usuario que crea el club es el admin inicial
  
      if @club.save
        # Crear una membresía automática para el creador del club
        Membership.create(user: current_user, club: @club, role: :admin)
        redirect_to @club, notice: 'Club was successfully created.'
      else
        render :new
      end
    end
  
    # Formulario para editar un club
    def edit
    end
  
    # Actualizar un club
    def update
      if @club.update(club_params)
        redirect_to @club, notice: 'Club was successfully updated.'
      else
        render :edit
      end
    end
  
    # Eliminar un club
    def destroy
      @club.destroy
      redirect_to clubs_url, notice: 'Club was successfully destroyed.'
    end
  
    # Solicitar unirse a un club
    def join
      if @club.memberships.where(user: current_user).exists?
        redirect_to @club, alert: 'You are already a member of this club.'
      else
        # Crear una membresía con estado "pending"
        Membership.create(user: current_user, club: @club, status: :pending)
        redirect_to @club, notice: 'Your request to join the club has been sent.'
      end
    end
  
    # Aprobar un miembro pendiente
    def approve_member
      membership = @club.memberships.find(params[:membership_id])
      if membership.update(status: :approved)
        redirect_to @club, notice: 'Member has been approved.'
      else
        redirect_to @club, alert: 'Failed to approve member.'
      end
    end
  
    private
  
    def set_club
      @club = Club.find(params[:id])
    end
  
    def club_params
      params.require(:club).permit(:name, :description, :address, :avatar)
    end
  end