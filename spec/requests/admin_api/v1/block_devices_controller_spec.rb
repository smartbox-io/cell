require "spec_helper"

RSpec.describe AdminApi::V1::BlockDevicesController do

  subject { response }

  let(:block_devices) do
    {
      sdb: {
        status: :accepted
      },
      sdc: {
        status: :accepted
      }
    }
  end
  let(:block_devices_params) { { block_devices: block_devices.keys.map(&:to_s) } }

  describe "#show" do
    it "shows the list of mounted block devices"
  end

  describe "#update" do
    def update
      patch admin_api_v1_block_devices_path, params: { block_devices: block_devices }
    end

    before { update }

    it { is_expected.to have_http_status :accepted }

    it "schedules the block device mounting" do
      allow(MountBlockDevicesJob).to receive(:perform_later).once.with block_devices_params
      update
      expect(MountBlockDevicesJob).to have_received(:perform_later).once.with block_devices_params
    end
  end

end
