class WelcomeController < ApplicationController
  def index
    @inbound_calls = Contact.inbound_calls.count
    @hang_ups = Contact.hang_ups.count
    @voice_info = Contact.voice_info.count
    @sms_info = Contact.sms_info.count
    @followed_up = Contact.followed_up.count

    @surveys_scheduled = Contact.surveys_scheduled.count
    @surveys_ongoing = Contact.surveys_ongoing.count
    @surveys_stalled = Contact.surveys_stalled.count

    @calls_data = {
      samples: [
        ["call_end", "Hangups", @hang_ups],
        ["call", "Voice info", @voice_info],
        ["chat_bubble_outline", "SMS info", @sms_info],
        ["check", "Follow ups", @followed_up]
      ],
      total:["Inbound calls", @inbound_calls]
    }

    @surveys_data = { d: [
      ["Follow ups", @followed_up],
      ["Ongoing", @surveys_ongoing],
      ["Stalled", @surveys_stalled],
      ["Pending follow ups", @surveys_scheduled]
    ]}

    @clinics = Clinic.without_deleted.all
    gon.clinics = @clinics
  end
end
