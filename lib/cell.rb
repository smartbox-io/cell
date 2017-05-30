class Cell

  require "socket"
  require "sys/filesystem"

  def self.machine_id
    File.read("/etc/machine-id").strip
  end

  def self.fqdn
    Socket.gethostbyname(Socket.gethostname).first
  rescue SocketError
    Socket.gethostname
  end

  def self.storage_volumes
    Hash[
      storage_mountpoints.values.map do |mountpoint|
        fs = Sys::Filesystem.stat mountpoint
        [
          mountpoint, {
            total_capacity: (fs.blocks * fs.block_size) / 1000 / 1000 / 1000,
            available_capacity: (fs.blocks_available * fs.block_size) / 1000 / 1000 / 1000
          }
        ]
      end
    ]
  end

  def self.mountpoints
    File.open("/proc/mounts", "r") { |f| f.readlines }.map do |line|
      line =~ /^([^\s]+)\s+([^\s]+)/
      [$1, $2]
    end
  end

  def self.storage_mountpoints
    Hash[
      mountpoints.select { |_, mountpoint| mountpoint =~ /^\/storage\d+/ }
    ]
  end

end
