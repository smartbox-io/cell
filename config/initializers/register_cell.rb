Brain.request(path: "/cluster-api/v1/cells/discovery",
              method: :post,
              payload: {
                cell: {
                  uuid: Cell.machine_uuid,
                  fqdn: Cell.fqdn,
                  volumes: Cell.storage_volumes,
                  public_ip_address: ENV["HOST_IP_ADDRESS"]
                }
              })
