class MountBlockDevicesJob < ApplicationJob
  queue_as :default

  def perform(block_devices:)
    Cell.mount_block_devices block_devices: block_devices
  end
end
