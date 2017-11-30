class AdminApi::V1::BlockDevicesController < AdminApplicationController
  def show
    # TODO
  end

  def update
    MountBlockDevicesJob.perform_later block_devices: block_devices_params[:block_devices].keys
    ok status: :accepted
  end

  private

  def block_devices_params
    params.permit block_devices: {}
  end
end
