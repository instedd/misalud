class ClinicsListing < Listings::Base
  include AuthenticatedListing

  model do
    authenticate!

    Clinic.without_deleted.select %{
      clinics.*,
      (SELECT count(*) FROM Contacts WHERE Contacts.survey_was_seen AND Contacts.survey_chosen_clinic_id = clinics.id) as contacts_seen,
      (SELECT count(*) FROM Contacts WHERE NOT(Contacts.survey_was_seen) AND Contacts.survey_chosen_clinic_id = clinics.id) as contacts_rejected
    }
  end

  scope :all, default: true
  scope 'to review', :sms_warning, lambda { |clinics|
    Kaminari.paginate_array(clinics.select { |c| !c.fits_sms? })
  }

  row_style do |clinic|
    'warning' unless clinic.fits_sms?
  end

  column '' do |clinic|
    unless clinic.fits_sms?
      content_tag(:a, href: Resmap.edit_site_url(clinic.resmap_id), target: "_blank") do
        content_tag(:i, class: 'material-icons tooltiped', "data-tooltip": clinic.fits_sms_message_errors.join("<br/>")) do
          "warning"
        end
      end
    end
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
