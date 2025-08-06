class MakeTeamJoinableOptional < ActiveRecord::Migration[8.0]
  def change
    # Hacer joinable_id y joinable_type opcionales
    change_column_null :teams, :joinable_id, true
    change_column_null :teams, :joinable_type, true
  end
end 