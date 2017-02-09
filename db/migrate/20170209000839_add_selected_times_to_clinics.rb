class AddSelectedTimesToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :selected_times, :integer
  end
end
