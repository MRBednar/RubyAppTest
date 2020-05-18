require 'net/http'

class Api::V1::SpotifyLoginController < ApplicationController

  # GET /spotify_client_secrets
  def index
    @spotify_client_secret = SpotifyClientSecret.find(3)

    @ClientId = @spotify_client_secret["ClientId"]
    @ClientSecret = @spotify_client_secret["ClientSecret"]


    @bearer = SpotifyLogin()

    playlisturi = URI.parse("https://api.spotify.com/v1/playlists/5y9L2Cy1RIZijyGlosVIvm/tracks")
    playlistHttp = Net::HTTP.new(playlisturi.host, playlisturi.port)
    playlistHttp.use_ssl = true
    playlistRequest = Net::HTTP::Get.new(playlisturi.request_uri)
    playlistRequest["authorization"] = "Bearer #{@bearer}"
    plalistResponse = playlistHttp.request(playlistRequest)

    rBody = JSON.parse(plalistResponse.body)

    items = rBody['items']
    trackIds = Array.new
    trackData = Array.new

    items.each {
      |i|
      artists = i['track']['artists'].first
      trackData << {name: i['track']['name'], id: i['track']['id'], artist: artists['name']}
      trackIds << i['track']['id']
    }

    trackFeatures = SpotifyAudioFeatures(trackIds)

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
      listResults << {Artist: td[:artist], Name: td[:name], Id: t['id'],Dance: t['danceability'], Energy: t['energy'], Tempo: t['tempo'], Valence: t['valence']}
    end

    trackCount = trackFeatures.count
    avgDance = cumulativeDance / trackCount
    avgEnergy = cumulativeEnergy / trackCount
    avgTemp = cumulativeTempo / trackCount
    avgValence = cumulativeValence / trackCount

    avgResults = {Dance: avgDance, Energy: avgEnergy, Tempo: avgTemp, Valence: avgValence}

    lastFmUrl = URI.parse("http://ws.audioscrobbler.com/2.0/")
    lastFmApiKey = "22c535a534224ffaa97e1eac4a889f60"
    lastFmQuerryParams = {:method => "track.getsimilar", :api_key => lastFmApiKey, :format => "json", :limit => 100}

    bestToAdd = Array.new

    addedCumulativeDance = 0
    addedCumulativeEnergy = 0
    addedCumulativeTempo = 0
    addedCumulativeValence = 0

    listResults.each do |q|
      lastFmQuerryParams[:artist] = q[:Artist]
      lastFmQuerryParams[:track] = q[:Name]
      lastFmUrl.query = URI.encode_www_form(lastFmQuerryParams)

      lastFmHttp = Net::HTTP.new(lastFmUrl.host, lastFmUrl.port)
      lastFmHttp.use_ssl = false

      lastFmRequest = Net::HTTP::Get.new(lastFmUrl.request_uri)

      lastFmResponse = lastFmHttp.request(lastFmRequest)

      lastResponse = JSON.parse(lastFmResponse.body)
      tracklist = lastResponse["similartracks"]["track"]

      if tracklist.length == 0
        next
      end
      similarIds = Array.new
      tracklist.each { |t|
        trackName = t["name"]
        artistName = t["artist"]["name"]
        storedTrackInfo = SpotifyTrackInfo.where("trackName = ? AND artistName = ?", trackName, artistName)

        if storedTrackInfo != nil && storedTrackInfo.count > 0
          testId = storedTrackInfo.first
          similarIds << {id: testId["spotifyId"], trackName: trackName, artistName: artistName}
        else
          spotifySearchUri = URI.parse("https://api.spotify.com/v1/search")
          songSub = trackName.gsub(" ", "%20")
          artistSub = artistName.gsub(" ", "%20")
          subQueryString = "artist:" + artistSub + "%20" + "track:" + songSub
          spotifySearchUri.query = "q=" + subQueryString + "&type=track&limit=1"
          searchHttp = Net::HTTP.new(spotifySearchUri.host, spotifySearchUri.port)
          searchHttp.use_ssl = true

          searchRequest = Net::HTTP::Get.new(spotifySearchUri.request_uri)
          searchRequest["authorization"] = "Bearer #{@bearer}"
          searchResponse = searchHttp.request(searchRequest)
          sBody = JSON.parse(searchResponse.body)
          searchResult = sBody["tracks"]["items"].first
          if searchResult != nil
            similarIds << {id: searchResult["id"], trackName: trackName, artistName: artistName}
            SpotifyTrackInfo.create(spotifyId: searchResult["id"], trackName: trackName, artistName: artistName)
          end
        end
      }

      idString = String.new
      similarIds.each { |l|
        idString = idString + l[:id] + ","
      }
      idString.delete_suffix(',')

      similarIdArray = idString.split(',')

      similarTracks = SpotifyAudioFeatures(similarIdArray)

      similarTrackData = Array.new
      similarTracks.each{|e|

        if e != nil
          similarTrack = similarIds.find {|f| f[:id] == e["id"]}
          similarTrackDataRow = {Dance: e['danceability'], Energy: e['energy'], Tempo: e['tempo'], Valence: e['valence']}
          if similarTrack != nil
            similarTrackDataRow[:trackName] = similarTrack[:trackName] if similarTrack[:trackName] != nil
            similarTrackDataRow[:artistName] = similarTrack[:artistName] if similarTrack[:artistName] != nil
          end

          danceAbs = CalcStatDiff(q[:Dance], e['danceability'])
          energyAbs = CalcStatDiff(q[:Energy], e['energy'])
          tempoAbs = ((q[:Tempo]-e['tempo']).abs).floor
          valenceAbs = CalcStatDiff(q[:Valence], e['valence'])
          similarTrackDataRow[:TotalDiff] = danceAbs + energyAbs + tempoAbs + valenceAbs
          similarTrackDataRow[:Dance]  = e['danceability']
          similarTrackDataRow[:Energy] = e['energy']
          similarTrackDataRow[:Tempo] = e['tempo']
          similarTrackDataRow[:Valence] = e['valence']
        end
        if similarTrackDataRow != nil
          similarTrackData << similarTrackDataRow
        end
      }

      if similarTrackData != nil
        bestPick = similarTrackData.min_by{|y| y[:TotalDiff]}
        addedCumulativeDance = addedCumulativeDance + bestPick[:Dance]
        addedCumulativeEnergy = addedCumulativeEnergy + bestPick[:Energy]
        addedCumulativeTempo = addedCumulativeTempo + bestPick[:Tempo]
        addedCumulativeValence = addedCumulativeValence + bestPick[:Valence]
        bestToAdd << {NewTrackName: bestPick[:trackName], NewArtistName: bestPick[:artistName], OriginalTrackName: q[:Name], OriginalArtist: q[:Artist]}
      end
    end

    avgAddedDance = addedCumulativeDance / bestToAdd.count
    avgAddedEnergy = addedCumulativeEnergy / bestToAdd.count
    avgAddedTempo = addedCumulativeTempo / bestToAdd.count
    avgAddedValence = addedCumulativeValence / bestToAdd.count

    avgAddedResults = {Dance: avgAddedDance, Energy: avgAddedEnergy, Tempo: avgAddedTempo, Valence: avgAddedValence}

    render :json => {AddedTracks: bestToAdd, OriginalAvg: avgResults, AddedAvg: avgAddedResults}
  end
end

def CalcStatDiff(song=0,suggestion=0)
  statDiff =  (song*1000-suggestion*1000).abs
  return (statDiff.floor)/10
end

def SpotifyLogin()
  oauthuri = URI.parse("https://accounts.spotify.com/api/token")

  authHttp = Net::HTTP.new(oauthuri.host, oauthuri.port)
  authHttp.use_ssl = true

  authRequest = Net::HTTP::Post.new(oauthuri.request_uri)
  authRequest.basic_auth(@ClientId, @ClientSecret)
  authRequest.set_form_data({"grant_type" => "client_credentials"})

  authResponse = authHttp.request(authRequest)

  puts authResponse

  authBody = JSON.parse(authResponse.body)

  return authBody["access_token"]
end

def SpotifyAudioFeatures(trackIds)
  spotifyTrackFeaturesUri = URI.parse("https://api.spotify.com/v1/audio-features")
  trackQueryParams = {:ids => trackIds.join(",")}
  spotifyTrackFeaturesUri.query = URI.encode_www_form(trackQueryParams)
  trackHttp = Net::HTTP.new(spotifyTrackFeaturesUri.host, spotifyTrackFeaturesUri.port)
  trackHttp.use_ssl = true

  trackRequest = Net::HTTP::Get.new(spotifyTrackFeaturesUri.request_uri)
  trackRequest["authorization"] = "Bearer #{@bearer}"

  trackResponse = trackHttp.request(trackRequest)

  tBody = JSON.parse(trackResponse.body)
  trackFeatures = tBody['audio_features']

  return trackFeatures
end
