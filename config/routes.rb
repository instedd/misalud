Rails.application.routes.draw do
  mount Listings::Engine => "/listings"

  root to: 'welcome#index'
  get '/map', to: 'welcome#map'

  post 'start_survey', to: 'welcome#start_survey'

  post 'twilio/sms'

  match "services/find-clinic", to: "services#find_clinic", via: [:get, :post]
  match "services/get-clinics", to: "services#get_clinics", via: [:get, :post]
  match "services/track-contact", to: "services#track_contact", via: [:get, :post]
  match "services/status-callback", to: "services#status_callback", via: [:get, :post]

  resources :clinics, only: :index do
    collection do
      post :sync
    end
  end

  resources :contacts, only: :index do
    member do
      post :start_survey
    end
  end
end
