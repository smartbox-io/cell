class Api::V1::ObjectsController < ApplicationController

  before_action :has_permissions?

  def create
    object = params[:object][:payload]
    File.open("/tmp/upload", "w") do |f|
      f.write object.read
    end
  end

  private

  def has_permissions?
    if !Brain.ok?(path: "/cluster-api/v1/upload-tokens/#{params[:upload_token]}",
                  query: { client_ip: request.remote_ip })
      forbidden
    end
  end

end
