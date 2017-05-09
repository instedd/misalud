class ApiController < ActionController::Base
  http_basic_authenticate_with name: Settings.api_basic_auth.username, password: Settings.api_basic_auth.password
end
