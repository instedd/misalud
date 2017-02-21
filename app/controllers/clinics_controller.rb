class ClinicsController < ApplicationController
  def index
  end

  def sync
    Clinic.import
    redirect_to clinics_path
  end
end
