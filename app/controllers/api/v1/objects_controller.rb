class Api::V1::ObjectsController < ApplicationController

  before_action :has_permissions?

  def create
    object_contents = params[:object][:payload].read
    digest = Cell.digest_contents object_contents
    object_name = digest[:sha256sum]
    object_path = File.join @volume, object_name
    File.open(object_path, "w") { |f| f.write object }
    Brain.request path: "/cluster-api/v1/objects",
                  method: :post,
                  payload: {
                    client_ip: request.remote_ip,
                    upload_token: params[:upload_token],
                    object: {
                      uuid: SecureRandom.uuid,
                      name: params[:object][:payload].original_filename,
                      size: File.size(object_path),
                      md5sum: digest[:md5sum],
                      sha1sum: digest[:sha1sum],
                      sha256sum: digest[:sha256sum]
                    }
                  },
                  access_token: @jwt
    ok
  end

  private

  def has_permissions?
    if !Brain.ok?(path: "/cluster-api/v1/upload-tokens/#{params[:upload_token]}",
                  query: { client_ip: request.remote_ip },
                  access_token: @jwt) do |json_response|
         @volume = json_response[:volume]
       end
      forbidden
    end
  end

end
