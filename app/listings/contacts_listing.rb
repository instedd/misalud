class ContactsListing < Listings::Base
  include LocalTimeHelper

  model do
    Contact.order(call_started_at: :desc)
  end

  scope :all, default: true
  scope :followed_up
  scope 'scheduled surveys', :surveys_scheduled
  scope 'ongoing surveys', :surveys_ongoing
  scope 'stalled surveys', :surveys_stalled
  scope :hang_ups

  export :csv, :xls

  column :phone, class: 'link' do |contact, phone|
    if format == :html
      link_to phone, phone_calls_contacts_url(phone: phone)
    else
      phone
    end
  end

  column :tracking_status, title: 'Status' do |contact, status|
    if format == :html
      status.humanize
    else
      status
    end
  end

  column :call_started_at do |contact, value|
    time(value)
  end

  column :survey_status do |contact, status|
    if format == :html
      status.try &:humanize
    else
      status
    end
  end

  column :survey_scheduled_at do |contact, value|
    time(value)
  end
  column :survey_can_be_called, title: 'Can be called?' do |_, value|
    boolean(value)
  end
  column :survey_was_seen, title: 'Seen?' do |_, value|
    boolean(value)
  end
  column survey_chosen_clinic: :name, title: 'Clinic'
  column :survey_clinic_rating, title: 'Satisfaction'
  column :survey_reason_not_seen, title: 'Reason' do |contact, reason|
    if format == :html
      reason.try &:humanize
    else
      reason
    end
  end

  column '', class: 'action' do |c|
    if format == :html
      link_to raw('<i class="material-icons">replay</i>'), start_survey_contact_path(c.id), class: "tooltiped", "data-tooltip": 'Restart survey', method: :post
    end
  end

  def boolean(value)
    if format == :html
      case value
      when nil
        "-"
      when true
        "Yes"
      when false
        "No"
      end
    else
      value.to_s.upcase
    end
  end

  def time(value)
    if format == :html
      local_time(value) if value
    else
      value
    end
  end
end
