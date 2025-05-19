class AddChallengeTypeToDuels < ActiveRecord::Migration[8.0]
  def change
    add_column :duels, :challenge_type, :integer
  end
end
