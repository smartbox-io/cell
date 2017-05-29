class Cell

  require "socket"

  def self.machine_id
    File.read("/etc/machine-id").strip
  end

  def self.fqdn
    Socket.gethostbyname(Socket.gethostname).first
  rescue SocketError
    Socket.gethostname
  end

end
