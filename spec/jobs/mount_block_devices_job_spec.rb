require "spec_helper"

RSpec.describe MountBlockDevicesJob do

  let(:cell_uuid)     { SecureRandom.uuid }
  let(:block_devices) { %w[sdb sdc sdd] }
  let(:block_device_partitions) do
    {
      sdb: {
        partitions: %i[sdb1 sdb2]
      },
      sdc: {
        partitions: %i[sdc1 sdc2]
      },
      sdd: {
        partitions: %i[sdd1 sdd2]
      }
    }
  end
  let(:block_devices_payload) do
    [
      {
        block_device: :sdb,
        status:       :healthy,
        partitions:   [
          { partition: :sdb1, status: :healthy },
          { partition: :sdb2, status: :healthy }
        ]
      },
      {
        block_device: :sdc,
        status:       :healthy,
        partitions:   [
          { partition: :sdc1, status: :healthy },
          { partition: :sdc2, status: :healthy }
        ]
      },
      {
        block_device: :sdd,
        status:       :healthy,
        partitions:   [
          { partition: :sdd1, status: :healthy },
          { partition: :sdd2, status: :healthy }
        ]
      }
    ]
  end
  let(:block_devices_params) do
    {
      path:    "/cluster-api/v1/cells/#{Cell.uuid}/block-devices",
      method:  :patch,
      payload: {
        cell: {
          block_devices: block_devices_payload
        }
      }
    }
  end

  before do
    allow(Cell).to receive(:uuid).and_return cell_uuid
    allow(Cell).to receive(:mount_block_devices).with(block_devices: block_devices)
                                                .and_return block_device_partitions
    allow(Brain).to receive(:request).with block_devices_params
    described_class.perform_now block_devices: block_devices
  end

  describe "#perform" do
    it "calls to Cell.mount_block_devices" do
      expect(Cell).to have_received(:mount_block_devices).with(block_devices: block_devices).once
    end

    it "notifies the brain about the mounted volumes" do
      expect(Brain).to have_received(:request).with(block_devices_params).once
    end
  end

end
