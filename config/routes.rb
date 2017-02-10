Rails.application.routes.draw do
  mount Listings::Engine => "/listings"

  root to: 'welcome#index'
  post 'start_survey', to: 'welcome#start_survey'

  post 'twilio/sms'

  match "services/find-clinic", to: "services#find_clinic", via: [:get, :post]
  match "services/track-contact", to: "services#track_contact", via: [:get, :post]
  match "services/status-callback", to: "services#status_callback", via: [:get, :post]
end
