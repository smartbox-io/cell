module LibSpecHelper
  def with_suppressed_output
    allow($stdout).to receive(:write)
    allow($stderr).to receive(:write)
  end
end
