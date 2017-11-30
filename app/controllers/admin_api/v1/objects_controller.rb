class AdminApi::V1::ObjectsController < AdminApplicationController
  before_action :permissions?
  before_action :target_allowed?

  def create
    object_contents, = Cell.request cell_ip: @source_cell_ip_address,
                                    path:    "/cluster-api/v1/objects/#{@object_uuid}/download",
                                    query:   { sync_token: params[:sync_token] }
    object_path = File.join @target_cell_volume, @object_sha256sum
    File.open(object_path, "w") { |f| f.write object_contents.body }
    # FIXME: notify brain
    ok
  end

  private

  def permissions?
    unless Brain.ok?(path: "/cluster-api/v1/sync-tokens/#{params[:sync_token]}") do |json_response|
             @object_uuid = json_response[:object][:uuid]
             @object_sha256sum = json_response[:object][:sha256sum]
             @target_cell_uuid = json_response[:target_cell][:uuid]
             @target_cell_volume = json_response[:target_cell][:volume]
             @source_cell_ip_address = json_response[:source_cell][:ip_address]
           end
      forbidden
    end
  end

  def target_allowed?
    forbidden if @target_cell_uuid != Cell.uuid
  end
end
