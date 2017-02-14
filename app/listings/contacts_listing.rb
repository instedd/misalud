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
  column 'Can be called?' do |c|
    c.survey_data["can_be_called"]
  end
  column 'Seen?' do |c|
    c.survey_data["seen"]
  end
  column 'Clinic' do |c|
    c.survey_data["clinic"]
  end
  column 'Satisfaction' do |c|
    c.survey_data["satisfaction"]
  end
  column 'Reason' do |c|
    c.survey_data["reason_not_seen"]
  end
  column do |c|
    if format == :html
      link_to raw('<i class="material-icons dp48">replay</i>'), start_survey_contact_path(c.id), method: :post, class: "waves-effect waves-teal btn-flat tooltipped", data: { position: 'bottom', tooltip: "Restart survey" }
    end
  end
end
