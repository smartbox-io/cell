class Brain

  require "net/http"

  def self.request(path:, method: :get, payload: nil, query: nil, access_token: nil)
    uri = URI("#{ENV["BRAIN_URL"]}#{path}")
    uri.query = URI.encode_www_form(query) if query
    http = Net::HTTP.new uri.host, uri.port
    req = case method
          when :head
            Net::HTTP::Head.new uri.request_uri
          when :get
            Net::HTTP::Get.new uri.request_uri
          when :post
            Net::HTTP::Post.new uri.request_uri, { "Content-Type" => "application/json" }
          when :put
            Net::HTTP::Put.new uri.request_uri, { "Content-Type" => "application/json" }
          when :patch
            Net::HTTP::Patch.new uri.request_uri, { "Content-Type" => "application/json" }
          when :delete
            Net::HTTP::Delete.new uri.request_uri
          else
            raise "unknown method"
          end
    if access_token
      req["Authorization"] = "Bearer #{access_token}"
    end
    if !%i(head get delete).include?(method) && payload
      req.body = payload.to_json
    end
    response = http.request req
    json_response = JSON.parse response.body, symbolize_names: true rescue nil
    if block_given?
      yield response, json_response
    else
      return response, json_response
    end
  end

  def self.ok?(path:, method: :get, payload: nil, query: nil, access_token: nil)
    request(path: path, method: method, payload: payload, query: query,
            access_token: access_token) do |response, json_response|
      response.code.to_i.between?(200, 299).tap do |ok|
        yield(json_response) if ok && block_given?
      end
    end
  end

end
