# app/services/goal_registrar.rb
class GoalRegistrar
    def initialize(duel, user, team, minute)
      @duel = duel
      @user = user
      @team = team
      @minute = minute
    end
  
    def register_goal
      DuelGoal.create!(
        duel: @duel,
        user: @user,
        team: @team,
        minute: @minute
      )
    end
  end