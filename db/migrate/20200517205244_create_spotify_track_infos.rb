class CreateSpotifyTrackInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :spotify_track_infos do |t|
      t.string :spotifyId
      t.string :trackName
      t.string :artistName

      t.timestamps
    end
  end
end
