require "spec_helper"

RSpec.describe Api::V1::ObjectsController do

  subject { response }

  let(:brain_response) do
    {
      volume: "/some/volume"
    }
  end

  describe "#create" do

    def create
      post api_v1_objects_path,
           params:  {
             object: {
               payload: fixture_file_upload(File.join("files", "some-file.txt"), "text/plain")
             }
           },
           headers: token_auth
    end

    context "it has permissions" do
      before do
        allow(Brain).to receive(:ok?) { |&block| block.call brain_response }
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:write_file)
        # rubocop:enable RSpec/AnyInstance
      end

      it "notifies the brain" do
        allow(Brain).to receive(:request)
          .with hash_including(path: "/cluster-api/v1/objects", method: :post)
        create
        expect(Brain).to have_received(:request)
          .with hash_including(path: "/cluster-api/v1/objects", method: :post)
      end
    end

    context "it doesn't have permissions" do
      before do
        allow(Brain).to receive(:ok?).and_return false
        create
      end

      it { is_expected.to have_http_status :forbidden }
    end

  end

end
