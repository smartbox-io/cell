require "spec_helper"

RSpec.describe ClusterApi::V1::Objects::DownloadController do

  subject { response }

  let(:object_uuid) { SecureRandom.uuid }
  let(:object_sha256sum) { Cell.digest_contents(SecureRandom.uuid)[:sha256sum] }
  let(:source_cell_uuid) { SecureRandom.uuid }
  let(:source_cell_volume) { "/some/volume" }
  let(:object_path) { File.join source_cell_volume, object_sha256sum }
  let(:other_source_cell_uuid) { SecureRandom.uuid }
  let(:target_cell_ip_address) { IPAddr.new(rand(2**32), Socket::AF_INET).to_s }
  let(:other_target_cell_ip_address) { IPAddr.new(rand(2**32), Socket::AF_INET).to_s }
  let(:sync_token) { SecureRandom.uuid }
  let(:show_params) { { sync_token: sync_token } }
  let(:brain_response) do
    {
      object:      {
        uuid:      object_uuid,
        sha256sum: object_sha256sum
      },
      source_cell: {
        uuid:   source_cell_uuid,
        volume: source_cell_volume
      },
      target_cell: {
        ip_address: target_cell_ip_address
      }
    }
  end

  describe "#show" do

    def show(remote_ip: target_cell_ip_address)
      get cluster_api_v1_download_path(object_uuid),
          params:  show_params,
          headers: ip(remote_ip)
    end

    context "it has permissions" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        allow(Cell).to receive(:uuid).and_return source_cell_uuid
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:send_file).with(object_path) do |c|
          c.render plain: object_uuid
        end
        # rubocop:enable RSpec/AnyInstance
        show
      end

      it "sends the file" do
        expect(response.body).to eq object_uuid
      end
    end

    context "it doesn't have permissions" do
      before do
        allow(Brain).to receive(:ok?).and_return false
        show
      end

      it { is_expected.to have_http_status :forbidden }
    end

    context "source is not allowed" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        allow(Cell).to receive(:uuid).and_return other_source_cell_uuid
        show
      end

      it { is_expected.to have_http_status :forbidden }
    end

    context "target IP address is not allowed" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        allow(Cell).to receive(:uuid).and_return source_cell_uuid
        show remote_ip: other_target_cell_ip_address
      end

      it { is_expected.to have_http_status :forbidden }
    end

  end

end
