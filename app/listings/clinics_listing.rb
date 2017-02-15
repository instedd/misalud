class ClinicsListing < Listings::Base

  model Clinic

  column :name
  column :address
  column :schedule
  column :walk_in_schedule
  column :selected_times, title: "# Suggested"
  column :rated_times, title: "# Selected"
  column :avg_rating, title: "Rating" do |clinic, rating|
    '%.2f' % rating if rating
  end

end
