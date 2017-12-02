class MountBlockDevicesJob < ApplicationJob
  queue_as :default

  def perform(block_devices:)
    block_devices = mount_block_devices block_devices: block_devices
    notify_brain block_devices: block_devices
  end

  private

  def mount_block_devices(block_devices:)
    block_devices = Cell.mount_block_devices block_devices: block_devices
    Hash[
      block_devices.map do |block_device, partitions|
        device_partitions block_device: block_device, partitions: partitions
      end
    ]
  end

  def device_partitions(block_device:, partitions:)
    [
      block_device,
      {
        status:     :healthy,
        partitions: Hash[partitions[:partitions].map do |partition|
                           [partition, status: :healthy]
                         end]
      }
    ]
  end

  def notify_brain(block_devices:)
    Brain.request path:    "/cluster-api/v1/cells/#{Cell.uuid}/block-devices",
                  method:  :patch,
                  payload: {
                    cell: {
                      block_devices: block_devices
                    }
                  }
  end
end
