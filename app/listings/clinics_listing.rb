class ClinicsListing < Listings::Base

  model do
    Clinic.without_deleted.select %{
      clinics.*,
      (SELECT count(*) FROM Contacts WHERE NOT(Contacts.survey_was_seen) AND Contacts.survey_chosen_clinic_id = clinics.id) as contacts_seen,
      (SELECT count(*) FROM Contacts WHERE Contacts.survey_was_seen AND Contacts.survey_chosen_clinic_id = clinics.id) as contacts_rejected
    }
  end

  column :name
  column :address
  column :schedule
  column :walk_in_schedule
  column :selected_times, title: "# Suggested"
  column :rated_times, title: "# Selected"
  column :contacts_seen, title: "# Seen", sortable: false
  column :contacts_rejected, title: "# Rejected", sortable: false
  column :avg_rating, title: "Rating" do |clinic, rating|
    '%.2f' % rating if rating
  end

end
