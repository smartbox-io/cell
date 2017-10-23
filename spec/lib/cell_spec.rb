require "spec_helper"
require "cell"

RSpec.describe Cell do

  let(:cell_uuid) { SecureRandom.uuid }
  let(:cell_ip) { "127.0.0.1" }
  let(:cell_fqdn) { "cell.example.com" }
  let(:path) { "/some/path" }
  let(:payload) { { some: "payload" } }
  let(:storage_mountpoints) { { "/dev/sdb1" => "/volumes/one", "/dev/sdc1" => "/volumes/two" } }
  let(:capacity) { { total_capacity: 107, available_capacity: 25 } }

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

  describe ".storage_volumes" do
    before do
      allow(described_class).to receive(:storage_mountpoints).and_return storage_mountpoints
      allow(Sys::Filesystem).to receive(:stat)
        .and_return(OpenStruct.new(blocks: 26214144, blocks_available: 6209006, block_size: 4096),
                    OpenStruct.new(blocks: 26214144, blocks_available: 6209006, block_size: 4096))
    end

    it "is expected to return the mountpoint along with the capacity" do
      expect(described_class.storage_volumes).to match(
        "/volumes/one" => capacity,
        "/volumes/two" => capacity
      )
    end
  end

  describe ".capacity" do
    let(:fs) { OpenStruct.new blocks: 26214144, blocks_available: 6209006, block_size: 4096 }

    it "is expected to return the capacity" do
      expect(described_class.capacity(fs: fs)).to match capacity
    end
  end

  describe ".mountpoints" do
    let(:mountpoints) do
      ["/dev/sdb1 /volumes/one", "/dev/sdc1 /volumes/two"]
    end

    before do
      allow(File).to receive(:open).with("/proc/mounts", "r").and_return mountpoints
    end

    it "returns tuples with device and mountpoint" do
      expect(described_class.mountpoints).to eq [["/dev/sdb1", "/volumes/one"],
                                                 ["/dev/sdc1", "/volumes/two"]]
    end
  end

  describe ".storage_mountpoints" do
    before do
      allow(described_class).to receive(:mountpoints).and_return(
        [["/dev/sda1", "/"],
         ["/dev/sdb1", "/volumes/one"],
         ["/dev/sdc1", "/volumes/two"]]
      )
    end

    it "filters out non storage mountpoints" do
      expect(described_class.storage_mountpoints).to match storage_mountpoints
    end
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
