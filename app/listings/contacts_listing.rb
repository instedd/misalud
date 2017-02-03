class ContactsListing < Listings::Base
  model Contact

  export :csv, :xls

  column :phone
  column :survey_status do |contact, status|
    if format == :html
      status.humanize
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
      link_to raw('<i class="material-icons dp48">replay</i>'), start_survey_path(phone: c.phone), method: :post, class: "waves-effect waves-teal btn-flat", title: "Restart survey"
    end
  end
end