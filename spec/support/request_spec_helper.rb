module RequestSpecHelper
  def basic_auth(user)
    {
      HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials(
        user.username,
        "password"
      )
    }
  end

  def token_auth(user)
    access_token = user.access_and_refresh_tokens
    {
      AUTHORIZATION: "Bearer #{access_token[:access_token]}"
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
