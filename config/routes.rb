Rails.application.routes.draw do
  get 'welcome#index'
  namespace :api do
    namespace :v1 do
      resources :spotify_client_secrets
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
