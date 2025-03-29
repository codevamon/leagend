class ChangeDuelIdToBeNullableInCallups < ActiveRecord::Migration[8.0]
  def change
    change_column_null :callups, :duel_id, true
  end
end
