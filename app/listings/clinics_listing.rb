class ClinicsListing < Listings::Base
  model Clinic

  column :name
  column :address
  column :schedule
  column :walk_in_schedule
  column :selected_times

end