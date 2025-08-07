class AddAssociationFieldsToDuels < ActiveRecord::Migration[8.0]
  def change
    add_reference :duels, :club, type: :string, foreign_key: true, null: true
    add_reference :duels, :clan, type: :string, foreign_key: true, null: true
    add_column :duels, :club_association_pending, :boolean, default: false
  end
end 