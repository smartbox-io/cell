class ClusterTokenlessApplicationController < ClusterApplicationController

  skip_before_action :load_jwt

end
