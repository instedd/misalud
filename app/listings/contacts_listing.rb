class ContactsListing < Listings::Base
  model Contact

  export :csv, :xls

  column :phone

  column :tracking_status, title: 'Status' do |contact, status|
    if format == :html
      status.humanize
    else
      status
    end
  end

  column :call_started_at

  column :survey_status do |contact, status|
    if format == :html
      status.try &:humanize
    else
      status
    end
  end

  column :survey_scheduled_at
  column :survey_can_be_called, title: 'Can be called?'
  column :survey_was_seen, title: 'Seen?'
  column survey_chosen_clinic: :name, title: 'Clinic'
  column :survey_clinic_rating, title: 'Satisfaction'
  column :survey_reason_not_seen, title: 'Reason' do |contact, reason|
    if format == :html
      reason.try &:humanize
    else
      reason
    end
  end

  column do |c|
    if format == :html
      link_to raw('<i class="material-icons dp48">replay</i>'), start_survey_contact_path(c.id), method: :post, class: "waves-effect waves-teal btn-flat tooltipped", data: { position: 'bottom', tooltip: "Restart survey" }
    end
  end
end
