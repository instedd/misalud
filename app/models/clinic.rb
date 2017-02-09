class Clinic < ApplicationRecord
  def self.import
    # TODO import from resmap collection
    (1..20).each do |i|
      import_clinic i, {
        "name" => "Name #{i}",
        "short_name" => "Short name #{i}",
        "address" => "Address #{i}",
        "schedule" => "Schedule #{i}",
        "walkin_schedule" => "Walkin_schedule #{i}"
      }
    end
  end

  def self.import_clinic(resmap_id, attributes)
    clinic = Clinic.find_or_initialize_by(resmap_id: resmap_id) do |clinic|
      # values for fresh clinics
      clinic.selected_times = 0
    end

    clinic.name = attributes["name"]
    clinic.short_name = attributes["short_name"]
    clinic.address = attributes["address"]
    clinic.schedule = attributes["schedule"]
    clinic.walkin_schedule = attributes["walkin_schedule"]

    clinic.save!
  end

  def self.pick(clinic_filter = {})
    # TODO use clinic_filter
    clinics = Clinic.order(selected_times: :asc)

    clinics = clinics.first(3)

    clinics.each do |c|
      c.with_lock do
        c.selected_times += 1
        c.save!
      end
    end

    clinics
  end
end
