# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  sidekiq_user = ENV['SIDEKIQ_WEB_USER']
  sidekiq_password = ENV['SIDEKIQ_WEB_PASSWORD']
  if sidekiq_user && sidekiq_password
    Sidekiq::Web.use ActionDispatch::Cookies
    Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_interslice_session'
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      [user, password] == [sidekiq_user, sidekiq_password]
    end
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :api do
    namespace :v1 do

      # Player
      get 'users/me', to: 'users#me', as: :me
      get 'inventory', to: 'inventory#show', as: :show_inventory
      post 'inventory/set_equipped', to: 'inventory#set_equipped', as: :set_equipped
      get 'base', to: 'base#show', as: :show_base
      post 'base', to: 'base#create', as: :create_base
      get 'journal/runestones', to: 'journal#runestones', as: :runestones

      resources :inventory_items, only: [:update]

      # World info
      resources :realm_locations, only: [:index]

      # Interactive locations
      resources :npcs, only: [:show] do
        resources :trade_offers, only: [] do
          post 'buy', to: 'trade_offers#buy', as: :buy
          post 'sell', to: 'trade_offers#sell', as: :sell
        end
      end
      resources :dungeons, only: [:show] do
        get 'analyze', to: 'dungeons#analyze', as: :analyze
        post 'battle', to: 'dungeons#battle', as: :battle
      end

      # Debug
      get 'monsters', to: 'monsters#index', as: :monsters
    end
  end
end
