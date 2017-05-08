class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Settings.basic_auth.username, password: Settings.basic_auth.password

  protect_from_forgery with: :exception
end
