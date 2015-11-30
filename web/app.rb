require 'sinatra/base'

require_relative '../lib/account'
require_relative '../lib/account_storage'
require_relative '../lib/api_client'

class CsvExportAddon < Sinatra::Base

  API_ENDPOINT = "http://localhost"
  API_PORT = "3000"
  CLIENT_ID = "58cfec7705d10221"
  CLIENT_SECRET = "h3YtB5rX0hL1mzkiUP1sN7Z6dMFiWqDf"


  before do
    @accounts   = RedisAccountStorage.new
    @api_client = ApiClient.new(API_ENDPOINT, API_PORT, CLIENT_ID, CLIENT_SECRET)
  end

  after do
    headers({ "X-Frame-Options" => "ALLOWALL" })
  end


  get "/domains/:account_id/csv" do
    account = @accounts.get(params[:account_id]) or halt 403
    @domains = @api_client.domains(account.id, account.access_token)

    haml :csv
  end

  post "/domains/:account_id/csv" do
    account = @accounts.get(params[:account_id]) or halt 403
    domains = @api_client.domains(account.id, account.access_token)

    content_type "application/csv"

    CSV.generate do |csv|
      domains.each do |domain|
        csv << [
          domain["name"],
          domain["state"],
          domain["expires_on"],
          domain["private_whois"],
          domain["auto_renew"]
        ]
      end
    end
  end


  get "/callback" do
    auth = @api_client.authorization(params[:code])

    @accounts.store(Account.new(auth.account_id, auth.access_token))

    haml :callback
  end

  get "/:account_id" do
    if account = @accounts.get(params[:account_id])
      redirect "/domains/#{account.id}/csv"
    else
      redirect @api_client.authorize_url
    end
  end

end
