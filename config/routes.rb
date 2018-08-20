Rails.application.routes.draw do
  root to: 'application#home', as: 'home'
  get '/players', to: 'application#players', as: 'all_players'
  # get: 'application#matchup', as: 'matchup'
  get '/login', to: 'sessions#new', as: 'login'
  post '/login', to: 'sessions#create', as: 'sign_in'
  delete '/logout', to: 'sessions#destroy', as: 'logout'

  resources :users
  resources :lineups do
    resources :players, only: [:index, :create, :show, :destroy]
    member do
      get 'compare'
      post 'add_comparison'
      delete 'drop_comparison'
      get 'roster'
      post 'set_roster'
    end
  end
end
