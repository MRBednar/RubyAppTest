require 'test_helper'

class SpotifyClientSecretsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @spotify_client_secret = spotify_client_secrets(:one)
  end

  test "should get index" do
    get spotify_client_secrets_url, as: :json
    assert_response :success
  end

  test "should create spotify_client_secret" do
    assert_difference('SpotifyClientSecret.count') do
      post spotify_client_secrets_url, params: { spotify_client_secret: { ClientId: @spotify_client_secret.ClientId, ClientSecret: @spotify_client_secret.ClientSecret } }, as: :json
    end

    assert_response 201
  end

  test "should show spotify_client_secret" do
    get spotify_client_secret_url(@spotify_client_secret), as: :json
    assert_response :success
  end

  test "should update spotify_client_secret" do
    patch spotify_client_secret_url(@spotify_client_secret), params: { spotify_client_secret: { ClientId: @spotify_client_secret.ClientId, ClientSecret: @spotify_client_secret.ClientSecret } }, as: :json
    assert_response 200
  end

  test "should destroy spotify_client_secret" do
    assert_difference('SpotifyClientSecret.count', -1) do
      delete spotify_client_secret_url(@spotify_client_secret), as: :json
    end

    assert_response 204
  end
end
