Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :api do
    namespace :v1 do
      get 'users/me' => 'users#me', as: :me
      resources :inventory, only: [:index]
      post '/inventory/set_equipped' => 'inventory#set_equipped', :as => :set_equipped

      resources :realm_locations, only: [:index]
      resources :npcs, only: [:show] do
        resources :trade_offers, only: [] do
          post 'buy', to: 'trade_offers#buy', as: :buy
          post 'sell', to: 'trade_offers#sell', as: :sell
        end
      end
      resources :dungeons, only: [:show]
      get '/dungeons/:id/analyze', to: 'dungeons#analyze', as: :analyze
      post '/dungeons/:id/battle', to: 'dungeons#battle', as: :battle
    end
  end
end
