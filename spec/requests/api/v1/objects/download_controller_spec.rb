require "spec_helper"

RSpec.describe Api::V1::Objects::DownloadController do

  subject { response }

  let(:object_uuid) { SecureRandom.uuid }

  before { get api_v1_download_path(object_uuid), headers: token_auth }

  it { is_expected.to have_http_status :not_found }

end
