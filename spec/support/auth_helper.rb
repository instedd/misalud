module AuthHelper
  def http_login_header
    user = Settings.basic_auth.username
    pw = Settings.basic_auth.password
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(user, pw) }
  end
end
