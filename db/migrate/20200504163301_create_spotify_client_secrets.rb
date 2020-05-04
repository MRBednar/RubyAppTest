class CreateSpotifyClientSecrets < ActiveRecord::Migration[6.0]
  def change
    create_table :spotify_client_secrets do |t|
      t.string :ClientId
      t.string :ClientSecret

      t.timestamps
    end
  end
end
