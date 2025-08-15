class FixDuelsLatlngPrecision < ActiveRecord::Migration[8.0]
  def change
    change_column :duels, :latitude,  :decimal, precision: 10, scale: 6
    change_column :duels, :longitude, :decimal, precision: 10, scale: 6
  end
end
