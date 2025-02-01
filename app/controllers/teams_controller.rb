# app/controllers/teams_controller.rb
class TeamsController < ApplicationController
    before_action :set_team, only: [:show, :edit, :update, :destroy]
  
    def new
      @team = Team.new
    end
  
    def create
      @team = Team.new(team_params)
      if @team.save
        # Asignar líder si se proporciona
        if params[:team][:leader_id].present?

          user = User.find_by(id: params[:team][:leader_id])
          if user && @team.users.include?(user)
            TeamMembership.create(team: @team, user: user, leader: true)
          else
            flash[:alert] = 'The selected leader is not a member of the team.'
          end
    
          # TeamMembership.create(team: @team, user_id: params[:team][:leader_id], leader: true)
        end
        redirect_to @team, notice: 'Team was successfully created.'
      else
        render :new
      end
    end
  
    def update
      if @team.update(team_params)
        # Actualizar líder si se proporciona
        if params[:team][:leader_id].present?

          user = User.find_by(id: params[:team][:leader_id])
          if user && @team.users.include?(user)
            @team.team_memberships.update_all(leader: false)
            TeamMembership.create(team: @team, user: user, leader: true)
          else
            flash[:alert] = 'The selected leader is not a member of the team.'
          end
          # Quitar el liderazgo actual
          # @team.team_memberships.update_all(leader: false)
          # Asignar nuevo líder
          # TeamMembership.create(team: @team, user_id: params[:team][:leader_id], leader: true)
        end
        redirect_to @team, notice: 'Team was successfully updated.'
      else
        render :edit
      end
    end
  
    private
  
    def set_team
      @team = Team.find(params[:id])
    end
  
    def team_params
      params.require(:team).permit(:name, :club_id, :clan_id, :leader_id)
    end
  end