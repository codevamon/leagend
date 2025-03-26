class DuelsController < ApplicationController
  before_action :set_teams, only: [:new, :create]

  # 🔹 Clásicos
  def new
    @duel = Duel.new
  end

  def create
    @duel = Duel.new(duel_params)
    if @duel.save
      RefereeAssigner.assign_to_duel(@duel)
      redirect_to @duel, notice: 'Duelo creado exitosamente.'
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :new
    end
  end

  def show
    @duel = Duel.includes(results: [:referee, :best_player]).find(params[:id])
    @home_team = @duel.home_team
    @away_team = @duel.away_team
    @home_team_users = @home_team.users
    @away_team_users = @away_team.users
  end

  # 🔹 Flujo personalizado paso a paso
  def select_team
    @memberships = current_user.memberships.includes(:club, :clan, :team)
    @team_options = @memberships.select { |m| m.clan.present? || (m.club.present? && m.admin?) }
  end

  def callup_players
    @team = Team.find(params[:team_id])
    @users = @team.users
  end

  def send_callup
    Callup.create(team_id: params[:team_id], user_id: params[:user_id], duel_id: params[:duel_id])
    Notification.create(user_id: params[:user_id], content: "Fuiste convocado a un duelo.")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def send_callups_to_all
    @team = Team.find(params[:team_id])
    @team.users.each do |user|
      Callup.find_or_create_by(team_id: @team.id, user_id: user.id, duel_id: params[:duel_id])
      Notification.create(user_id: user.id, content: "Fuiste convocado a un duelo.")
    end
    redirect_to callup_players_duels_path(team_id: @team.id), notice: 'Todos convocados.'
  end

  def select_arena
    @duel = Duel.find(params[:duel_id])
    @arenas = Arena.all.select { |a| a.available_between?(@duel.starts_at, @duel.ends_at) }
  end

  def open_duels
    @duels = Duel.where(status: :pending, private: false, opponent_id: nil)
  end

  def select_type
    @duel = Duel.find(params[:duel_id])
  end

  def confirm
    @duel = Duel.new(duel_params)
    RefereeAssigner.assign_to_duel(@duel) if params[:assign_referee] == '1'

    if @duel.save
      redirect_to @duel, notice: "Duelo creado con éxito."
    else
      flash.now[:alert] = @duel.errors.full_messages.to_sentence
      render :select_type
    end
  end

  # 🔹 Funciones complementarias
  def start
    @duel = Duel.find(params[:id])
    @duel.update(status: 'started', managed_by_leaders: @duel.referee.nil?)
  end

  def add_goal
    duel = Duel.find(params[:id])
    user = User.find(params[:user_id])
    team = Team.find(params[:team_id])
    minute = params[:minute]

    GoalRegistrar.new(duel, user, team, minute).register_goal
    redirect_to duel, notice: 'Gol registrado exitosamente.'
  end

  private

    def set_teams
      @teams = Team.all
    end

    def duel_params
      params.require(:duel).permit(
        :home_team_id, :away_team_id,
        :referee_id, :best_player_id,
        :arena_id, :starts_at, :ends_at,
        :address, :neighborhood, :city, :country,
        :latitude, :longitude,
        :price, :budget, :budget_place, :budget_equipment, :referee_price,
        :status, :duel_type, :duration,
        :timing, :referee_required, :live, :private, :streaming,
        :audience, :parking, :wifi, :lockers, :snacks,
        :home_goals, :away_goals, :hunted, :responsibility
      )
    end
end
