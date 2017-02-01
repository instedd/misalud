Rails.application.routes.draw do
  mount Listings::Engine => "/listings"

  root to: 'welcome#index'
  post 'start_survey', to: 'welcome#start_survey'

  post 'twilio/sms'

  match "services/find-clinic", to: "services#find_clinic", via: [:get, :post]
end
