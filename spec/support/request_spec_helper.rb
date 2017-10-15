module RequestSpecHelper
  def basic_auth(user)
    {
      HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials(
        user.username,
        "password"
      )
    }
  end
end
