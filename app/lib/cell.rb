class Cell

  require "socket"
  require "fileutils"
  require "securerandom"
  require "sys/filesystem"

  def self.digest_contents(contents)
    {
      md5sum: Digest::MD5.hexdigest(contents),
      sha1sum: Digest::SHA1.hexdigest(contents),
      sha256sum: Digest::SHA256.hexdigest(contents)
    }
  end

  def self.uuid
    File.read("/etc/cell/uuid").strip
  rescue Errno::ENOENT
    FileUtils.mkdir_p "/etc/cell"
    SecureRandom.uuid.tap do |uuid|
      File.open("/etc/cell/uuid", "w") { |f| f.write uuid }
    end
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
      mountpoints.select { |_, mountpoint| mountpoint =~ /^\/volumes/ }
    ]
  end

  def self.request(cell_ip:, path:, method: :get, payload: nil, query: nil)
    uri = URI("http://#{cell_ip}#{path}")
    uri.query = URI.encode_www_form(query) if query
    http = Net::HTTP.new uri.host, uri.port
    req = case method
          when :head
            Net::HTTP::Head.new uri.request_uri
          when :get
            Net::HTTP::Get.new uri.request_uri
          when :post
            Net::HTTP::Post.new uri.request_uri, { "Content-Type" => "application/json" }
          when :put
            Net::HTTP::Put.new uri.request_uri, { "Content-Type" => "application/json" }
          when :patch
            Net::HTTP::Patch.new uri.request_uri, { "Content-Type" => "application/json" }
          when :delete
            Net::HTTP::Delete.new uri.request_uri
          else
            raise "unknown method"
          end
    if !%i(head get delete).include?(method) && payload
      req.body = payload.to_json
    end
    response = http.request req
    json_response = JSON.parse response.body, symbolize_names: true rescue nil
    if block_given?
      yield response, json_response
    else
      return response, json_response
    end
  end

end
