class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update]
  before_action :set_user, only: [:show, :edit, :update]

  def show
    # Lógica para mostrar el perfil del usuario
  end

  def edit
    # Lógica para editar el perfil del usuario
    @user = current_user
  end
  
  def index
  end

  def callups
    @callups = current_user.callups.includes(:teamable, :duel).order(created_at: :desc)
  end

  def update
    # if @user.update(user_params)
    #   redirect_to @user, notice: 'User was successfully updated.'
    # else
    #   render :edit
    # end

    @user = current_user
    if @user.update(user_params)
      redirect_to @user, notice: "Perfil actualizado correctamente."
    else
      render :edit
    end
  end

  private
  
    def set_user
      if params[:id] =~ /\A\d+\z/ || User.friendly.exists?(slug: params[:id])
        @user = User.friendly.find(params[:id])
      else
        redirect_to root_path, alert: "User not found."
      end
    end
  
  
      def user_params
        params.require(:user).permit(:phone_number, :pin, :latitude, :longitude, :avatar, :coverpage, :firstname, :lastname, :email, :bio)
      end
end
