class PublicController < ActionController::Base
  layout "public"

  def clinics
    ids = [params[:id1], params[:id2], params[:id3]].compact
    @clinics = Clinic.find(ids)
  end
end
