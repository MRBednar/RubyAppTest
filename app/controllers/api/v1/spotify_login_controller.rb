require 'net/http'

class Api::V1::SpotifyLoginController < ApplicationController

  # GET /spotify_client_secrets
  def index
    @spotify_client_secret = SpotifyClientSecret.find(3)
    uri = URI.parse("https://accounts.spotify.com/authorize")

    @ClientId = @spotify_client_secret["ClientId"]
    @ClientSecret = @spotify_client_secret["ClientSecret"]
    redirect = CGI.escape("http://127.0.0.1:3000/api/v1/spotify_login/")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request.set_form_data({"client_id" => @ClientId, "response_type" => "code", "redirect_uri" => redirect})

    response = http.request(request)
    render :json => response.body
  end
end
