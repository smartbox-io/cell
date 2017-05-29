Brain.request(path: "/cluster-api/v1/cells/discovery",
              method: :post,
              payload: {
                cell: {
                  uuid: Cell.machine_id,
                  fqdn: Cell.fqdn
                }
              })
