class Brain

  require "net/http"

  def self.request(path:, method: :get, payload: nil, query: nil, access_token: nil)
    uri = URI("#{ENV["BRAIN_URL"]}#{path}")
    uri.query = URI.encode_www_form(query) if query
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
    json_response = JSON.parse response.body, symbolize_names: true
    if block_given?
      yield response, json_response
    else
      return response, json_response
    end
  end

  def self.ok?(path:, method: :get, payload: nil, query: nil, access_token: nil)
    response, json_response = request path: path, method: method, payload: payload, query: query,
                                      access_token: access_token
    response.code.to_i.between? 200, 299
  end

end
