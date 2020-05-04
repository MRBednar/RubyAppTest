class Api::V1::SpotifyClientSecretsController < ApplicationController
  before_action :set_spotify_client_secret, only: [:show, :update, :destroy]

  # GET /spotify_client_secrets
  def index
    @spotify_client_secrets = SpotifyClientSecret.all

    render json: @spotify_client_secrets
  end

  # GET /spotify_client_secrets/1
  def show
    render json: @spotify_client_secret
  end

  # POST /spotify_client_secrets
  def create
    @spotify_client_secret = SpotifyClientSecret.new(spotify_client_secret_params)

    if @spotify_client_secret.save
      render json: @spotify_client_secret, status: :created, location: api_v1_spotify_client_secrets_url(@spotify_client_secret)
    else
      render json: @spotify_client_secret.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /spotify_client_secrets/1
  def update
    if @spotify_client_secret.update(spotify_client_secret_params)
      render json: @spotify_client_secret
    else
      render json: @spotify_client_secret.errors, status: :unprocessable_entity
    end
  end

  # DELETE /spotify_client_secrets/1
  def destroy
    @spotify_client_secret.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_spotify_client_secret
      @spotify_client_secret = SpotifyClientSecret.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def spotify_client_secret_params
      params.require(:spotify_client_secret).permit(:ClientId, :ClientSecret)
    end
end
