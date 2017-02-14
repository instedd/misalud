namespace :data do
  desc "Generates fake data for the application"
  task fake: :environment do

    # Generate 20 clinics
    (1..20).each do |i|
      Clinic.import_clinic i, {
        "name" => "Clinic Name #{i}",
        "short_name" => "Short name #{i}",
        "address" => "Address #{i}",
        "schedule" => "Mon-Fri 9-18, Sat-Sun 9-15",
        "walk_in_schedule" => "Mon-Sat 9-13",
        "free_clinic" => (i % 3 == 0),
        "women_care" => (i % 4 == 1),
        "latitude" => 40.7128 + (rand - 0.5),
        "longitude" => -74.0059 + (rand - 0.5),
        "borough" => Borough[(i % 5 + 1)].try(:name)
      }
    end

    # Generate 50 contacts
    clinics = Clinic.all
    (0..50).each do |i|
      contact = Contact.find_or_initialize_by(call_sid: i+1)
      contact.phone = 9990000 + i
      contact.tracking_status = "voice_info"
      contact.pregnant = (i % 5 == 0)
      contact.urgent = (i % 3 == 0)
      contact.known_condition = (i % 4 == 0)
      contact.borough = Borough[(i % 5 + 1)].try(:name)
      contact.language = (i % 2 == 0 ? "en" : "es")
      contact.sms_requested = (i % 7 != 0)
      contact.call_started_at = (rand(10)+1).days.ago
      contact.survey_data = {
        "reason_not_seen" => MessageProcessor::NOT_SEEN_REASON.values.sample,
        "seen" => [true, false].sample,
        "clinic" => rand(3) + 1,
        "can_be_called" => [true, false].sample,
        "satisfaction" => rand(5) + 1
      } if (i % 8 != 0)

      contact.clinic1, contact.clinic2, contact.clinic3 = clinics.sample(3)
      contact.save!
    end

    puts "Done!"
  end
end
