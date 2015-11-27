class ApiClient
  def initialize(url, port, client_id, client_secret)
    @url = url
    @port = port
    @client_id = client_id
    @client_secret = client_secret
  end

  def authorize_url
    "#{@url}:#{@port}/oauth/authorize?client_id=#{@client_id}&response_type=code&state=1234567"
  end

  def authorization(code)
    body = { client_id: @client_id, client_secret: @client_secret, code: code, state: "1234567" }
    auth = HTTParty.post("#{@url}:#{@port}/oauth/access_token", body: body)

    Auth.new(auth["account_id"].to_s, auth["access_token"].to_s)
  end

  def domains(account_id, access_token)
    query    = { "_api" => "1" }
    headers  = { "Authorization" => "Bearer #{access_token}" }
    response = HTTParty.get("#{@url}:#{@port}/v2/#{account_id}/domains", query: query, headers: headers)
    response["data"]
  end

  Auth = Struct.new(:account_id, :access_token)
end