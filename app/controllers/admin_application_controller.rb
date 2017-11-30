class AdminApplicationController < ApplicationController
  skip_before_action :load_jwt
end
