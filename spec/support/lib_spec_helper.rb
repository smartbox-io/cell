module LibSpecHelper
  def with_suppressed_output
    allow(STDOUT).to receive(:puts)
  end
end
