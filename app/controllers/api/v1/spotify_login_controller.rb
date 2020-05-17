require 'net/http'

class Api::V1::SpotifyLoginController < ApplicationController

  # GET /spotify_client_secrets
  def index
    @spotify_client_secret = SpotifyClientSecret.find(3)

    @ClientId = @spotify_client_secret["ClientId"]
    @ClientSecret = @spotify_client_secret["ClientSecret"]

    oauthuri = URI.parse("https://accounts.spotify.com/api/token")

    authHttp = Net::HTTP.new(oauthuri.host, oauthuri.port)
    authHttp.use_ssl = true

    authRequest = Net::HTTP::Post.new(oauthuri.request_uri)
    authRequest.basic_auth(@ClientId, @ClientSecret)
    authRequest.set_form_data({"grant_type" => "client_credentials"})

    authResponse = authHttp.request(authRequest)

    authBody = JSON.parse(authResponse.body)
    bearer = authBody['access_token']

    uri = URI.parse("https://api.spotify.com/v1/playlists/5y9L2Cy1RIZijyGlosVIvm/tracks")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request["authorization"] = "Bearer #{bearer}"


    response = http.request(request)

    rBody = JSON.parse(response.body)
    items = rBody['items']
    trackIds = Array.new
    trackData = Array.new

    items.each {
      |i| trackData << {name: i['track']['name'], id: i['track']['id']}
      trackIds << i['track']['id']
    }

    spotifyTrackFeaturesUri = URI.parse("https://api.spotify.com/v1/audio-features")
    trackQueryParams = {:ids => trackIds.join(",")}
    spotifyTrackFeaturesUri.query = URI.encode_www_form(trackQueryParams)
    trackHttp = Net::HTTP.new(spotifyTrackFeaturesUri.host, spotifyTrackFeaturesUri.port)
    trackHttp.use_ssl = true

    trackRequest = Net::HTTP::Get.new(spotifyTrackFeaturesUri.request_uri)
    trackRequest["authorization"] = "Bearer #{bearer}"

    trackResponse = trackHttp.request(trackRequest)

    tBody = JSON.parse(trackResponse.body)
    trackFeatures = tBody['audio_features']

    cumulativeDance = 0
    cumulativeEnergy = 0
    cumulativeTempo = 0
    cumulativeValence = 0

    listResults = Array.new

    trackFeatures.each do |t|
      cumulativeDance = cumulativeDance + t['danceability']
      cumulativeEnergy = cumulativeEnergy + t['energy']
      cumulativeTempo = cumulativeTempo + t['tempo']
      cumulativeValence = cumulativeValence + t['valence']
      td = trackData.find { |z| z[:id] == t['id'] }
      listResults << {Name: td[:name], Id: t['id'],Dance: t['danceability'], Energy: t['energy'], Tempo: t['tempo'], Valence: t['valence']}
    end

    trackCount = trackFeatures.count
    avgDance = cumulativeDance / trackCount
    avgEnergy = cumulativeEnergy / trackCount
    avgTemp = cumulativeTempo / trackCount
    avgValence = cumulativeValence / trackCount

    avgResults = {Dance: avgDance, Energy: avgEnergy, Tempo: avgTemp, Valence: avgValence}

    finalResults = {ListResults: listResults, AverageResults: avgResults}

    render :json => finalResults
  end
end
