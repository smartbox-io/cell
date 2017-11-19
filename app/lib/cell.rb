# rubocop:disable Metrics/ClassLength
class Cell
  require "socket"
  require "pathname"
  require "fileutils"
  require "securerandom"
  require "sys/filesystem"

  def self.digest_contents(contents)
    {
      md5sum:    Digest::MD5.hexdigest(contents),
      sha1sum:   Digest::SHA1.hexdigest(contents),
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

  def self.block_devices
    devices = Pathname.new("/sys/block").children.select do |device|
      device.directory? && block_device?(device: device)
    end
    Hash[devices.map do |device|
      [device.basename.to_s.to_sym,
       total_capacity: File.read(File.join(device.to_s, "size")).strip.to_i,
       partitions:     device_partitions(block_device: device.basename.to_s)]
    end]
  end

  def self.block_device?(device:)
    device.basename.to_s !~ /^loop/ &&
      (!File.exist?(File.join(device.to_s, "/device/type")) ||
       File.read(File.join(device.to_s, "/device/type")).strip.to_i.zero?)
  end

  def self.device_partitions(block_device:)
    partitions = Pathname.new(File.join("/sys/block", block_device)).children.select do |partition|
      partition.directory? && partition.basename.to_s =~ /^#{block_device}\d+/
    end
    partitions.map! do |partition|
      [partition.basename.to_s.to_sym,
       total_capacity: File.read(File.join(partition.to_s, "size")).strip.to_i]
    end
    Hash[partitions]
  end

  def self.storage_volumes
    Hash[
      storage_mountpoints.values.map do |mountpoint|
        fs = Sys::Filesystem.stat mountpoint
        [mountpoint, capacity(fs: fs)]
      end
    ]
  end

  def self.capacity(fs:)
    {
      total_capacity:     (fs.blocks * fs.block_size) / 1000 / 1000 / 1000,
      available_capacity: (fs.blocks_available * fs.block_size) / 1000 / 1000 / 1000
    }
  end

  def self.mountpoints
    File.open("/proc/mounts", "r", &:readlines).map do |line|
      device, mountpoint = line.scan(/^([^\s]+)\s+([^\s]+)/).first
      [device, mountpoint]
    end
  end

  def self.storage_mountpoints
    Hash[
      mountpoints.select { |_, mountpoint| mountpoint =~ /^\/volumes/ }
    ]
  end

  def self.request(cell_ip:, path:, method: :get, payload: nil, query: nil)
    response = perform_request cell_ip: cell_ip, path: path, method: method, payload: payload,
                               query: query
    json_response = begin
                      JSON.parse response.body, symbolize_names: true
                    rescue JSON::ParserError
                      nil
                    end
    return response, json_response unless block_given?
    yield response, json_response
  end

  def self.perform_request(cell_ip:, path:, method:, payload:, query:)
    uri = URI("http://#{cell_ip}#{path}")
    uri.query = URI.encode_www_form(query) if query
    http = Net::HTTP.new uri.host, uri.port
    req = build_request uri: uri, method: method
    req.body = payload.to_json if !%i[head get delete].include?(method) && payload
    http.request req
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.build_request(uri:, method:)
    case method
    when :head   then Net::HTTP::Head.new   uri.request_uri
    when :get    then Net::HTTP::Get.new    uri.request_uri
    when :post   then Net::HTTP::Post.new   uri.request_uri, "Content-Type" => "application/json"
    when :put    then Net::HTTP::Put.new    uri.request_uri, "Content-Type" => "application/json"
    when :patch  then Net::HTTP::Patch.new  uri.request_uri, "Content-Type" => "application/json"
    when :delete then Net::HTTP::Delete.new uri.request_uri
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
# rubocop:enable Metrics/ClassLength
