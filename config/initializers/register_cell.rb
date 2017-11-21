if Rails.env.production?
  res, = Brain.request(path:    "/cluster-api/v1/cells/discovery",
                       method:  :post,
                       payload: {
                         cell: {
                           uuid:              Cell.uuid,
                           fqdn:              Cell.fqdn,
                           block_devices:     Cell.block_devices,
                           public_ip_address: ENV["HOST_IP_ADDRESS"]
                         }
                       })
  raise "Could not register cell" unless res.code.to_i == 200
end
