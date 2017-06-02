class Clinic < ApplicationRecord
  acts_as_paranoid without_default_scope: true

  has_many :raters, class_name: "Contact", foreign_key: "survey_chosen_clinic_id"

  def display_name
    short_name.presence || name
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

  CLINIC_SAMPLE_SIZE = 3
  MAX_SMS_LENGTH = 160
  GSM_CHARACTERS = /^[@£$¥èéùìòÇ\fØø\nÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-.\/[0-9]:;<=>\?¡[A-Z]ÄÖÑÜ§¿[a-z]äöñüà\^\{\}\[~\]\|€]+/

  def fits_sms_message_errors
    # the display names are combined with ", '1' for {display_name}" in `MessageProcessor#clinic_short_names_as_options`
    # and some instruction prefix text need to added
    max_display_name_size = (
      (
        MAX_SMS_LENGTH - I18n.t('survey.which_clinic_did_you_choose').size - I18n.t('survey.reply_with').size - 10 * CLINIC_SAMPLE_SIZE
      ) / CLINIC_SAMPLE_SIZE
    ).floor

    @fits_sms_message_errors ||= begin
      res = []

      res << "short_name needs to be shorter than #{max_display_name_size} chars." if self.display_name.size > max_display_name_size

      validate_sms(res, "sms info with walk in schedule", self.sms_info(true))
      validate_sms(res, "sms info with regular schedule ", self.sms_info(false))

      res
    end
  end

  def validate_sms(res, prefix, sms)
    gsm_valid = sms.match(GSM_CHARACTERS)[0]
    if gsm_valid.size < sms.size
      res << "#{prefix} has some gsm invalid text: #{sms[gsm_valid.size]}."
    end
    res << "#{prefix} is #{sms.size} chars long instead of #{MAX_SMS_LENGTH}." if  sms.size > MAX_SMS_LENGTH
  end

  def fits_sms?
    fits_sms_message_errors.size == 0
  end

  def sms_info(urgent)
    schedule = urgent ? self.walk_in_schedule : self.schedule
    [self.name, self.address, self.borough_label, schedule].map(&:presence).compact.map{|s| s.gsub("–","-")}.join(", ")
  end

  def self.import
    ids = Clinic.all.pluck(:id)
    Resmap.new.import_sites do |site|
      import_clinic(site.id, site.properties.merge("name" => site.name, "latitude" => site.lat, "longitude" => site.long), ids)
    end
    # ids hold all the ids that were not imported in resmap, hence should be soft deleted
    ids.each { |id| Clinic.find(id).delete }
  end

  def self.import_clinic(resmap_id, attributes, ids = nil)
    clinic = Clinic.find_or_initialize_by(resmap_id: resmap_id) do |clinic|
      # Values for fresh clinics
      clinic.selected_times = 0
    end

    ids.delete(clinic.id) if ids

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
    clinics = filtered(filter).all.sample(CLINIC_SAMPLE_SIZE)

    clinics.each do |c|
      c.with_lock do
        c.selected_times += 1
        c.save!
      end
    end

    clinics
  end

  def self.filtered(filter = {})
    clinics = Clinic.without_deleted

    clinics = clinics.where(women_care: true) if filter[:pregnancy]
    clinics = clinics.where(borough: filter[:borough]) if filter[:borough]
    clinics = clinics.order(free_clinic: (filter[:free_clinic] ? :asc : :desc))

    return clinics
  end
end
