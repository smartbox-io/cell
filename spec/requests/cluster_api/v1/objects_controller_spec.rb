require "spec_helper"

RSpec.describe ClusterApi::V1::ObjectsController do

  subject { response }

  let(:object_uuid) { SecureRandom.uuid }
  let(:object_sha256sum) { Digest::SHA256.hexdigest SecureRandom.uuid }
  let(:target_cell_uuid) { SecureRandom.uuid }
  let(:target_cell_volume) { "/some/volume" }
  let(:other_target_cell_uuid) { SecureRandom.uuid }
  let(:source_cell_ip_address) { IPAddr.new(rand(2**32), Socket::AF_INET).to_s }
  let(:sync_token) { SecureRandom.uuid }
  let(:create_params) { { sync_token: sync_token } }
  let(:brain_response) do
    {
      object:      {
        uuid:      object_uuid,
        sha256sum: object_sha256sum
      },
      target_cell: {
        uuid:   target_cell_uuid,
        volume: target_cell_volume
      },
      source_cell: {
        ip_address: source_cell_ip_address
      }
    }
  end

  describe "#create" do

    def create
      post cluster_api_v1_objects_path, params:  create_params.to_json,
                                        headers: json_content_type
    end

    context "it has permissions" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        allow(Cell).to receive(:uuid).and_return target_cell_uuid
        allow(Cell).to receive :request
        allow(File).to receive :open
        create
      end

      it { is_expected.to have_http_status :ok }
    end

    context "it doesn't have permissions" do
      before do
        allow(Brain).to receive(:ok?).and_return false
        create
      end

      it { is_expected.to have_http_status :forbidden }
    end

    context "target is not allowed" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        allow(Cell).to receive(:uuid).and_return other_target_cell_uuid
        create
      end

      it { is_expected.to have_http_status :forbidden }
    end

  end

end
