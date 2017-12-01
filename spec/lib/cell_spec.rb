require "spec_helper"
require "cell"

RSpec.describe Cell do

  let(:cell_uuid)           { SecureRandom.uuid }
  let(:cell_ip)             { "127.0.0.1" }
  let(:cell_fqdn)           { "cell.example.com" }
  let(:path)                { "/some/path" }
  let(:payload)             { { some: "payload" } }
  let(:loop_device)         { OpenStruct.new basename: "loop0" }
  let(:block_device)        { OpenStruct.new basename: "sdb" }
  let(:storage_mountpoints) { { "/dev/sdb1" => "/volumes/one", "/dev/sdc1" => "/volumes/two" } }
  let(:capacity)            { { total_capacity: 107, available_capacity: 25 } }

  describe ".digest_contents" do
    subject { described_class.digest_contents "some contents" }

    it do
      is_expected.to match hash_including(md5sum:    a_kind_of(String),
                                          sha1sum:   a_kind_of(String),
                                          sha256sum: a_kind_of(String))
    end
  end

  describe ".uuid" do
    context "when the uuid file exists" do
      before do
        allow(File).to receive(:read).with("/etc/cell/uuid").and_return cell_uuid
      end

      it "returns the cell uuid" do
        expect(described_class.uuid).to eq cell_uuid
      end
    end

    context "when the uuid file does not exist" do
      before do
        allow(File).to receive(:read).with("/etc/cell/uuid").and_raise Errno::ENOENT
      end

      it "creates the /etc/cell directory" do
        allow(FileUtils).to receive(:mkdir_p).with "/etc/cell"
        allow(File).to receive(:open).with "/etc/cell/uuid", "w"
        described_class.uuid
        expect(FileUtils).to have_received(:mkdir_p).with "/etc/cell"
      end

      it "writes the uuid file" do
        allow(FileUtils).to receive(:mkdir_p).with "/etc/cell"
        allow(File).to receive(:open).with "/etc/cell/uuid", "w"
        described_class.uuid
        expect(File).to have_received(:open).with "/etc/cell/uuid", "w"
      end
    end
  end

  describe ".fqdn" do
    context "gethostbyname succesfully returns" do
      before do
        allow(Socket).to receive(:gethostbyname).and_return [cell_fqdn]
      end

      subject { described_class.fqdn }

      it { is_expected.to eq cell_fqdn }
    end

    context "gethostbyname fails" do
      before do
        allow(Socket).to receive(:gethostbyname).and_raise SocketError
        allow(Socket).to receive(:gethostname).and_return cell_fqdn
      end

      subject { described_class.fqdn }

      it { is_expected.to eq cell_fqdn }
    end
  end

  describe ".mount_block_devices" do
    subject { mount_block_devices }

    let(:block_devices)                { %i[sda sdb sdc] }
    let(:mount_block_devices)          do
      described_class.mount_block_devices block_devices: block_devices
    end
    let(:block_devices_and_partitions) do
      {
        sda: { partitions: [:sdx1] },
        sdb: { partitions: [:sdx1] },
        sdc: { partitions: [:sdx1] }
      }
    end

    before do
      allow(described_class).to receive(:block_devices).and_return sda: [], sdb: [], sdc: []
      allow(described_class).to receive(:mount_block_device)
        .exactly(block_devices.count).times.and_return [:sdx1]
    end

    it { is_expected.to match block_devices_and_partitions }
  end

  describe ".mount_block_device" do
    subject { mount_block_device }

    let(:block_device)           { :sda }
    let(:block_device_partition) { :sda1 }
    let(:mount_block_device)     { described_class.mount_block_device block_device: block_device }

    before do
      allow(described_class).to receive(:device_partitions).and_return(sda1: {})
      allow(described_class).to receive(:mount_block_device_partition)
        .with(block_device_partition: block_device_partition).and_return true
    end

    it { is_expected.to match [block_device_partition] }
  end

  describe ".mount_block_device_partition" do
    let(:block_device_partition)     { :sdb }
    let(:block_device_partition_dev) { "/dev/#{block_device_partition}" }
    let(:volume)                     { "/volumes/#{block_device_partition}" }
    let(:mount_args)                 { "mount #{block_device_partition_dev} #{volume}" }
    let(:mount_block_device) do
      described_class.mount_block_device_partition block_device_partition: block_device_partition
    end

    before do
      allow(FileUtils).to receive(:mkdir_p).with(volume).once
      allow(described_class).to receive(:system).with(mount_args).once
      mount_block_device
    end

    it "creates the mountpoint" do
      expect(FileUtils).to have_received(:mkdir_p).with(volume).once
    end

    it "mounts the device" do
      expect(described_class).to have_received(:system).with(mount_args).once
    end
  end

  describe ".block_devices" do
    subject { described_class.block_devices }

    let(:partitions) do
      {
        sdb1: { total_capacity: 2103296 },
        sdb2: { total_capacity: 16771072 },
        sdb3: { total_capacity: 209713152 },
        sdb4: { total_capacity: 771624960 }
      }
    end

    before do
      allow(Pathname).to receive(:new).with("/sys/block").and_return(
        OpenStruct.new(children: [OpenStruct.new(basename: "sdb", directory?: true)])
      )
      allow(described_class).to receive(:block_device?).and_return true
      allow(File).to receive(:read).and_return "1000215216"
      allow(described_class).to receive(:device_partitions).with(block_device: "sdb").and_return(
        partitions
      )
    end

    it { is_expected.to eq sdb: { total_capacity: (1000215216 * 512), partitions: partitions } }
  end

  describe ".block_device?" do
    context "it is a loop device" do
      subject { described_class.block_device? device: loop_device }

      it { is_expected.to eq false }
    end

    context "/device/type is missing" do
      before do
        allow(File).to receive(:exist?).and_return false
      end

      subject { described_class.block_device? device: block_device }

      it { is_expected.to eq true }
    end

    context "/device/type exists and equals 0" do
      before do
        allow(File).to receive(:exist?).and_return true
        allow(File).to receive(:read).and_return "0"
      end

      subject { described_class.block_device? device: block_device }

      it { is_expected.to eq true }
    end

    context "/device/type exists and does not equal 0" do
      before do
        allow(File).to receive(:exist?).and_return true
        allow(File).to receive(:read).and_return "1"
      end

      subject { described_class.block_device? device: block_device }

      it { is_expected.to eq false }
    end
  end

  describe ".device_partitions" do
    before do
      allow(Pathname).to receive(:new).with("/sys/block/sdb").and_return(
        OpenStruct.new(children: [OpenStruct.new(basename: "sdb1", directory?: true)])
      )
      allow(File).to receive(:read).and_return "1024"
    end

    subject { described_class.device_partitions block_device: "sdb" }

    it { is_expected.to eq(sdb1: { total_capacity: (1024 * 512) }) }
  end

  describe ".request" do
    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Net::HTTP).to receive(:request).and_return(
        OpenStruct.new(body: '{ "some": "json" }')
      )
      # rubocop:enable RSpec/AnyInstance
    end

    context "head request" do
      subject { described_class.request(cell_ip: cell_ip, path: path, method: :head).second }

      it { is_expected.to eq some: "json" }
    end

    context "get request" do
      subject { described_class.request(cell_ip: cell_ip, path: path, method: :get).second }

      it { is_expected.to eq some: "json" }
    end

    context "post request" do
      subject do
        described_class.request(cell_ip: cell_ip, path: path, method: :post,
                                payload: payload).second
      end

      it { is_expected.to eq some: "json" }
    end

    context "put request" do
      subject do
        described_class.request(cell_ip: cell_ip, path: path, method: :put,
                                payload: payload).second
      end

      it { is_expected.to eq some: "json" }
    end

    context "patch request" do
      subject do
        described_class.request(cell_ip: cell_ip, path: path, method: :patch,
                                payload: payload).second
      end

      it { is_expected.to eq some: "json" }
    end

    context "delete request" do
      subject { described_class.request(cell_ip: cell_ip, path: path, method: :delete).second }

      it { is_expected.to eq some: "json" }
    end

    context "with a json parsing error on the response" do
      before do
        allow(JSON).to receive(:parse).and_raise JSON::ParserError
      end

      subject { described_class.request(cell_ip: cell_ip, path: path, method: :get).second }

      it { is_expected.to be_nil }
    end

    context "when a block has been passed" do
      it "yields the expected times" do
        expect { |b| described_class.request cell_ip: cell_ip, path: path, method: :get, &b }
          .to yield_control.exactly(1).times
      end

      it "yields with the expected information" do
        expect do |b|
          described_class.request cell_ip: cell_ip, path: path, method: :get, &b
        end.to yield_with_args(anything, some: "json")
      end
    end
  end

end
