module RequestSpecHelper
  def basic_auth(username = "username", password = "password")
    {
      HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials(
        username,
        password
      )
    }
  end

  def token_auth(token = nil)
    token ||= "jwt-token"
    {
      AUTHORIZATION: "Bearer #{token}"
    }
  end

  def content_type(content_type)
    { "Content-Type" => content_type }
  end

  def json_content_type
    content_type "application/json"
  end

  def ip(ip)
    { REMOTE_ADDR: ip }
  end
end
