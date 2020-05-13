class CreateAppUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :app_users do |t|
      t.string :Name, limit: 50
      t.integer :spotifySecretsId, limit: 2
      t.string :password, limit: 16

      t.timestamps
    end
  end
end
