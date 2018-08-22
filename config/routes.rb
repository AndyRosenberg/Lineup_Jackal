Rails.application.routes.draw do
  root to: 'application#home', as: 'home'
  # get: 'application#matchup', as: 'matchup'
  get '/login', to: 'sessions#new', as: 'login'
  post '/login', to: 'sessions#create', as: 'sign_in'
  delete '/logout', to: 'sessions#destroy', as: 'logout'

  resources :users do
    collection do
      get 'forgot'
      post 'validate_forgot'
    end

    member do 
      get 'reset'
      post 'validate_reset'
    end
  end

  resources :lineups do
    resources :players, only: [:index, :create, :destroy]
    member do
      get 'compare'
      post 'add_comparison'
      get 'roster'
      post 'set_roster'
    end
  end

  resources :players, only: [:show] do
    collection do
      # get 'search'
      get 'all', to: 'players#flex_index', as: 'all'
      post 'flex_create', as: 'flex_create'
    end
  end
end
