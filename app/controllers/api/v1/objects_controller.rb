class Api::V1::ObjectsController < ApplicationController
  before_action :permissions?

  # rubocop:disable Metrics/MethodLength
  def create
    object_contents = params[:object][:payload].read
    digest = Cell.digest_contents object_contents
    object_name = digest[:sha256sum]
    object_path = File.join @volume, object_name
    object_size = write_file object_path: object_path, object_contents: object_contents
    notify_brain object_size: object_size, digest: digest
    ok payload: {
      object: {
        name: object_name
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  private

  def permissions?
    unless Brain.ok?(path:         "/cluster-api/v1/upload-tokens/#{params[:upload_token]}",
                     query:        { client_ip: request.remote_ip },
                     access_token: @jwt) do |json_response|
             puts json_response
             @volume = json_response[:volume]
           end
      forbidden
    end
  end

  # :nocov:
  def write_file(object_path:, object_contents:)
    File.open(object_path, "w") { |f| f.write object_contents }
  end
  # :nocov:

  # rubocop:disable Metrics/MethodLength
  def notify_brain(object_size:, digest:)
    Brain.request path:         "/cluster-api/v1/objects",
                  method:       :post,
                  payload:      {
                    client_ip:    request.remote_ip,
                    upload_token: params[:upload_token],
                    object:       {
                      uuid:      SecureRandom.uuid,
                      name:      params[:object][:payload].original_filename,
                      size:      object_size,
                      md5sum:    digest[:md5sum],
                      sha1sum:   digest[:sha1sum],
                      sha256sum: digest[:sha256sum]
                    }
                  },
                  access_token: @jwt
  end
  # rubocop:enable Metrics/MethodLength
end
