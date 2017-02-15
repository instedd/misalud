class AddRatingToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :rated_times, :integer, default: 0
    add_column :clinics, :avg_rating, :float
  end
end
