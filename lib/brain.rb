class Brain

  require "net/http"

  def self.request(path:, method: :get, payload: nil, access_token: nil)
    uri = URI("#{ENV["BRAIN_URL"]}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    req = case method
          when :get
            Net::HTTP::Get.new(uri.path)
          when :post
            Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
          else
            raise "unknown method"
          end
    if access_token
      req["Authorization"] = "Bearer #{access_token}"
    end
    if !%i(get head).include?(method) && payload
      req.body = payload.to_json
    end
    response = http.request req
    json_response = JSON.parse(response.body, symbolize_names: true)
    yield response, json_response if block_given?
    return response, json_response
  end

end
