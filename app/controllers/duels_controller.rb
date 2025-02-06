class DuelsController < ApplicationController
  before_action :set_teams, only: [:new, :create]

  def new
    @duel = Duel.new
  end

  def create
    home_team = Team.find(params[:home_team_id])
    away_team = Team.find(params[:away_team_id])
    date = params[:duel][:start_date]
    location = params[:duel][:address]
    referee_id = params[:duel][:referee_id]
    
    if home_team.nil? || away_team.nil?
      redirect_to new_duel_path, alert: 'One or both teams could not be found.'
      return
    end

    # duel = DuelCreator.new(home_team, away_team, date, location, referee_id).create_duel
    duel = DuelCreator.new(home_team, away_team, params[:duel][:start_date], params[:duel][:address], params[:duel][:referee_id]).create_duel

    if duel.persisted?
      # Asignar árbitro aleatorio
      RefereeAssigner.assign_to_duel(duel)
      redirect_to duel, notice: 'Duel created successfully.'
    else
      render :new, alert: 'Failed to create duel.'
    end
  end
  
  def show
    @duel = Duel.find(params[:id])
    @home_team = @duel.home_team
    @away_team = @duel.away_team

    # Cargar los usuarios del home_team y away_team
    @home_team_users = @home_team.users
    @away_team_users = @away_team.users
  end
  
  def start
    @duel = Duel.find(params[:id])
    if @duel.referee.nil?
      # Lógica para duelos sin árbitro
      @duel.update(status: 'started', managed_by_leaders: true)
    else
      # Lógica para duelos con árbitro
      @duel.update(status: 'started')
    end
  end

  
  def add_goal
    duel = Duel.find(params[:id])
    user = User.find(params[:user_id])
    team = Team.find(params[:team_id])
    minute = params[:minute]

    GoalRegistrar.new(duel, user, team, minute).register_goal

    redirect_to duel, notice: 'Goal registered successfully.'
  end

  private

    def set_teams
      @teams = Team.all
    end
end