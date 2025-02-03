class CallupsController < ApplicationController
    before_action :set_team
    before_action :set_duel
  
    def new
      @users = @team.users
    end
  
    def create
      user = User.find(params[:user_id])
  
      callup = @team.callups.new(user: user, duel: @duel)
  
      if callup.save
        redirect_to @team, notice: 'User has been called up successfully.'
      else
        redirect_to @team, alert: 'Failed to call up user.'
      end
    end
  
    private
  
    def set_team
      @team = Team.find(params[:team_id])
    end
  
    def set_duel
      @duel = Duel.find(params[:duel_id])
    end
  end