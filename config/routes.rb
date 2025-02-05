Rails.application.routes.draw do

  # Root route
  root to: 'pages#home'
  

  # Resources for main models
  resources :clubs do
    resources :teams, only: [:index, :new, :create]
    resources :admins, only: [:index, :new, :create]
    resources :memberships, only: [:create]
    member do
      patch 'memberships/:id/approve', to: 'memberships#approve', as: :approve_membership
    end
    member do
      post :join
      post :approve_member
    end
  end

  resources :clans do
    resources :teams, only: [:index, :new, :create]
    resources :admins, only: [:index, :new, :create]
    resources :memberships, only: [:create]
    member do
      post :join
    end
  end

  resources :teams, except: [:index, :new, :create] do
    resources :team_memberships, only: [:index, :new, :create, :destroy]
    resources :duels, only: [:index, :new, :create]
    member do
      resources :callups, only: [:new, :create]
      get :callup_users
      post :create_callup
      patch :assign_leader
    end
  end

  resources :duels do
    resources :lineups, only: [:index, :new, :create, :destroy]
    resources :duel_goals, only: [:index, :new, :create, :destroy]
    resources :results, only: [:new, :create, :edit, :update]
    member do
      patch :start
      patch :complete
    end
  end

  resources :referees, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  # User profiles
  resources :users, only: [:show, :edit, :update] do
    member do
      get :stats
    end
  end

  # Admin namespace for administrative actions
  namespace :admin do
    resources :users, only: [:index, :show, :edit, :update, :destroy]
    resources :clubs, only: [:index, :show, :edit, :update, :destroy]
    resources :clans, only: [:index, :show, :edit, :update, :destroy]
    resources :teams, only: [:index, :show, :edit, :update, :destroy]
    resources :duels, only: [:index, :show, :edit, :update, :destroy]
    resources :referees, only: [:index, :show, :edit, :update, :destroy]
  end

  # API namespace for future API endpoints
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show]
      resources :clubs, only: [:index, :show]
      resources :clans, only: [:index, :show]
      resources :teams, only: [:index, :show]
      resources :duels, only: [:index, :show]
      resources :referees, only: [:index, :show]
    end
  end

  devise_for :users,
              path: '',
              path_names: {
                sign_in: 'login', 
                sign_out: 'logout', 
                edit: 'users/:id/edit',
                # sign_up: 'registration' 
              }, 
              controllers: {
                omniauth_callbacks: 'users/omniauth_callbacks'
              }
  # # Custom routes for specific actions
  # get 'dashboard', to: 'dashboard#index'
  # get 'search', to: 'search#index'
  # post 'search', to: 'search#results'

  # # Error handling
  # match '/404', to: 'errors#not_found', via: :all
  # match '/500', to: 'errors#internal_server_error', via: :all

  # # Catch-all route for undefined routes
  # match '*path', to: 'errors#not_found', via: :all
end