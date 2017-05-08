module AuthenticatedListing
  include ActionController::HttpAuthentication::Basic

  def authenticate!
    raise unless has_basic_credentials?(request)

    name, password = user_name_and_password(request)

    raise unless (ActiveSupport::SecurityUtils.variable_size_secure_compare(name, Settings.basic_auth.username) &
            ActiveSupport::SecurityUtils.variable_size_secure_compare(password, Settings.basic_auth.password))
  end
end
