class AdminsController < ApplicationController
    before_action :set_admin, only: [:show, :edit, :update, :destroy]
    before_action :clean_expired_teams


    def index
      @admins = Admin.all
    end
  
    def show
    end
  
    def new
      @admin = Admin.new
    end
  
    def create
      @admin = Admin.new(admin_params)
      if @admin.save
        redirect_to @admin, notice: 'Admin was successfully created.'
      else
        render :new
      end
    end
  
    def edit
    end
  
    def update
      if @admin.update(admin_params)
        redirect_to @admin, notice: 'Admin was successfully updated.'
      else
        render :edit
      end
    end
  
    def destroy
      @admin.destroy
      redirect_to admins_url, notice: 'Admin was successfully destroyed.'
    end
  
    private
  
      def set_admin
        @admin = Admin.find(params[:id])
      end
    
      def admin_params
        params.require(:admin).permit(:user_id, :club_id, :clan_id, :level)
      end
      
      def clean_expired_teams
        DestroyExpiredTeamsJob.perform_later if rand < 0.1 # ejecuta solo el 10% de las veces para evitar carga innecesaria
      end
  end