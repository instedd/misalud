Rails.application.routes.draw do
  mount Listings::Engine => "/listings"

  root to: 'welcome#index'
  post 'start_survey', to: 'welcome#start_survey'

  post 'twilio/sms'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
