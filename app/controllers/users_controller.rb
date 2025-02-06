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
      @user = User.friendly.find(params[:id])
      end
  
      def user_params
        params.require(:user).permit(:phone_number, :pin, :latitude, :longitude, :avatar, :coverpage, :firstname, :lastname, :email, :bio)
      end
end
