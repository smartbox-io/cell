class ApplicationController < ActionController::API

  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :load_jwt

  private

  def forbidden
    head :forbidden
  end

  def load_jwt
    authenticate_or_request_with_http_token do |jwt, options|
      @jwt = jwt
    end
  end

end
