class ClansController < ApplicationController
    before_action :set_clan, only: [:show, :edit, :update, :destroy, :join]
    before_action :authenticate_user!, except: [:index, :show]
  
    # Listar todos los clans
    def index
      @clans = Clan.all
    end
  
    # Mostrar un clan específico
    def show
      @members = @clan.users
      @clan = Clan.find(params[:id])
      @memberships = @clan.memberships.approved
    end
  
    # Formulario para crear un nuevo clan
    def new
      @clan = Clan.new
    end
  
    # Crear un nuevo clan
    def create
      @clan = Clan.new(clan_params)
      @clan.user = current_user # El usuario que crea el clan es el admin inicial
  
      if @clan.save
        # Crear una membresía automática para el creador del clan
        Membership.create(user: current_user, clan: @clan, role: :admin)
        redirect_to @clan, notice: 'Clan was successfully created.'
      else
        render :new
      end
    end
  
    # Formulario para editar un clan
    def edit
    end
  
    # Actualizar un clan
    def update
      if @clan.update(clan_params)
        redirect_to @clan, notice: 'Clan was successfully updated.'
      else
        render :edit
      end
    end
  
    # Eliminar un clan
    def destroy
      @clan.destroy
      redirect_to clans_url, notice: 'Clan was successfully destroyed.'
    end
  
    # Unirse a un clan (sin necesidad de aprobación)
    def join
      if @clan.memberships.where(user: current_user).exists?
        redirect_to @clan, alert: 'You are already a member of this clan.'
      else
        # Crear una membresía automática
        Membership.create(user: current_user, clan: @clan, status: :approved)
        redirect_to @clan, notice: 'You have successfully joined the clan.'
      end
    end
  
    private
  
    def set_clan
      @clan = Clan.find(params[:id])
    end
  
    def clan_params
      params.require(:clan).permit(:name, :description, :address, :avatar)
    end
  end