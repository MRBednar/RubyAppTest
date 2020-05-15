require 'net/http'

class Api::V1::SpotifyLoginController < ApplicationController

  # GET /spotify_client_secrets
  def index
    @spotify_client_secret = SpotifyClientSecret.find(4)

    @ClientId = @spotify_client_secret["ClientId"]
    @ClientSecret = @spotify_client_secret["ClientSecret"]

    oauthuri = URI.parse("https://api.twitter.com/oauth2/token")

    authHttp = Net::HTTP.new(oauthuri.host, oauthuri.port)
    authHttp.use_ssl = true

    authRequest = Net::HTTP::Post.new(oauthuri.request_uri)
    authRequest.basic_auth(@ClientId, @ClientSecret)
    authRequest.set_form_data({"grant_type" => "client_credentials"})

    authResponse = authHttp.request(authRequest)

    authBody = JSON.parse(authResponse.body)
    bearer = authBody['access_token']

    uri = URI.parse("https://api.twitter.com/1.1/search/tweets.json")
    queryParams = {:q => "from%3AGwainT%20agree"}
    uri.query = URI.encode_www_form(queryParams)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request["authorization"] = "Bearer #{bearer}"


    response = http.request(request)

    render :json => response.body
  end
end
