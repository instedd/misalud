class AddAttributesToClinics < ActiveRecord::Migration[5.0]
  def change
    add_column :clinics, :free_clinic, :boolean, default: false
    add_column :clinics, :women_care, :boolean, default: false
    add_column :clinics, :latitude, :float
    add_column :clinics, :longitude, :float
    rename_column :clinics, :walkin_schedule, :walk_in_schedule
  end
end
