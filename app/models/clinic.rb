class Clinic < ApplicationRecord

  has_many :raters, class_name: "Contact", foreign_key: "survey_chosen_clinic_id"

  def display_name
    name.presence || short_name
  end

  def borough_label
    Borough[self.borough].try(:label)
  end

  def add_rating!(rating)
    with_lock do
      self.avg_rating = if rated_times == 0
        rating
      else
        (avg_rating * rated_times + rating).to_f / (rated_times + 1)
      end
      self.rated_times += 1
      save!
    end
  end

  def self.import
    Resmap.new.import_sites { |site| import_clinic(site.id, site.properties.merge("name" => site.name, "latitude" => site.lat, "longitude" => site.long)) }
  end

  def self.import_clinic(resmap_id, attributes)
    clinic = Clinic.find_or_initialize_by(resmap_id: resmap_id) do |clinic|
      # Values for fresh clinics
      clinic.selected_times = 0
    end

    clinic.name = attributes["name"]
    clinic.short_name = attributes["short_name"]
    clinic.address = attributes["address"]
    clinic.schedule = attributes["schedule"]
    clinic.borough = attributes["borough"]
    clinic.walk_in_schedule = attributes["walk_in_schedule"]
    clinic.free_clinic = attributes["free_clinic"]
    clinic.women_care = attributes["women_care"]
    clinic.latitude ||= attributes["latitude"]
    clinic.longitude ||= attributes["longitude"]

    clinic.save!
    clinic
  end

  def self.pick(filter = {})
    # TODO: prioritise those with fewer visits so far
    clinics = filtered(filter).all.sample(3)

    clinics.each do |c|
      c.with_lock do
        c.selected_times += 1
        c.save!
      end
    end

    clinics
  end

  def self.filtered(filter = {})
    clinics = Clinic

    # Disregard all other filters if it's women seeking care
    if filter[:pregnancy]
      return clinics.where(women_care: true)
    end

    clinics = clinics.where(borough: filter[:borough]) if filter[:borough]
    clinics = clinics.order(free_clinic: (filter[:free_clinic] ? :asc : :desc))

    return clinics
  end
end
