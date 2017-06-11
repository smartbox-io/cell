class ClusterApi::V1::Objects::DownloadController < ClusterApplicationController

  before_action :has_permissions?
  before_action :object_matches?
  before_action :source_allowed?
  before_action :target_ip_address_allowed?

  def show
    send_file File.join(@source_cell_volume, @object_sha256sum)
  end

  private

  def has_permissions?
    if !Brain.ok?(path: "/cluster-api/v1/sync-tokens/#{params[:sync_token]}") do |json_response|
         @object_uuid = json_response[:object][:uuid]
         @object_sha256sum = json_response[:object][:sha256sum]
         @source_cell_uuid = json_response[:source_cell][:uuid]
         @source_cell_volume = json_response[:source_cell][:volume]
         @target_cell_ip_address = json_response[:target_cell][:ip_address]
       end
      forbidden
    end
  end

  def object_matches?
    forbidden if @object_uuid != params[:uuid]
  end

  def source_allowed?
    forbidden if @source_cell_uuid != Cell.machine_uuid
  end

  def target_ip_address_allowed?
    forbidden if @target_cell_ip_address != request.remote_ip
  end

end
