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
      resources :dungeons, only: [:show]
      post '/dungeons/:id/battle' => 'dungeons#battle', :as => :battle
    end
  end
end
