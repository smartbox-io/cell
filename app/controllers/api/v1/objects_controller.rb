class Api::V1::ObjectsController < ApplicationController

  before_action :has_permissions?

  def create
    object = params[:object][:payload].read
    object_name = Digest::SHA256.hexdigest object
    File.open("/storage1/#{object_name}", "w") do |f|
      f.write object
    end
  end

  private

  def has_permissions?
    if !Brain.ok?(path: "/cluster-api/v1/upload-tokens/#{params[:upload_token]}",
                  query: { client_ip: request.remote_ip },
                  access_token: @jwt)
      forbidden
    end
  end

end
