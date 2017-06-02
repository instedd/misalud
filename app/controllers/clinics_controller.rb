class ClinicsController < ApplicationController
  def index
    clinics = Clinic.without_deleted
    @clinics_total = clinics.group(:borough).count
    @clinics_women_total = clinics.where(women_care: true).group(:borough).count
    @borough = Borough.all
  end

  def sync
    Clinic.import
    redirect_to clinics_path
  end
end
