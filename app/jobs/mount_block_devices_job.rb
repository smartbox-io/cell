class MountBlockDevicesJob < ApplicationJob
  queue_as :default

  def perform(block_devices:)
    block_devices = mount_block_devices block_devices: block_devices
    notify_brain block_devices: block_devices
  end

  private

  def mount_block_devices(block_devices:)
    block_devices = Cell.mount_block_devices block_devices: block_devices
    block_devices.map do |block_device|
      {
        device:  block_device[:device],
        status:  :healthy,
        volumes: block_device[:volumes].map { |volume| { volume: volume, status: :healthy } }
      }
    end
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
