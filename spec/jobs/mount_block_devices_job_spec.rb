require "spec_helper"

RSpec.describe MountBlockDevicesJob do

  let(:block_devices) { %w[sdb sdc sdd] }

  describe "#perform" do
    it "calls to Cell.mount_block_devices" do
      allow(Cell).to receive(:mount_block_devices).with block_devices: block_devices
      described_class.perform_now block_devices: block_devices
      expect(Cell).to have_received(:mount_block_devices).with(block_devices: block_devices).once
    end
  end

end
