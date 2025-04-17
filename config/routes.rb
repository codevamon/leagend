Rails.application.routes.draw do
  root to: 'pages#home'


  post 'duels/create_team_and_callup', to: 'duels#create_team_and_callup', as: :create_team_and_callup_duels
  post 'duels/send_callups_to_all', to: 'duels#send_callups_to_all', as: :send_callups_to_all_duels
  post 'duels/finalize_creation', to: 'duels#finalize_creation', as: :finalize_creation_duels
  post 'duels/:duel_id/accept', to: 'duels#accept_opponent', as: :accept_open_duel
  get "duels/open", to: "duels#open", as: :open_duels


  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }
  resources :users, only: [:index, :show, :edit, :update, :destroy]
  resources :notifications, only: [:index, :update] do
    collection do
      put :mark_all_read
    end
  end



  # Clubs y Clans
  resources :clubs do
    resources :teams, only: [:index, :new, :create]
    resources :admins, only: [:index, :new, :create]
    resources :memberships, only: [:create, :destroy]
    post :join, on: :member
  end

  resources :clans do
    resources :teams, only: [:index, :new, :create]
    resources :admins, only: [:index, :new, :create]
    resources :memberships, only: [:create, :destroy]
    post :join, on: :member
  end

  # Equipos y duelos
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
    collection do
      get :when
      get :select_team      # Paso 1: escoger equipo válido
      get :callup_players   # Paso 2: convocar jugadores
      post :send_callup     # enviar una convocatoria
      get :select_arena     # Paso 3: escoger arena y mostrar mapa
      # get :open_duels       # Tab adicional con duelos abiertos
      get :select_type      # Paso 4: tipo de duelo y referee
      post :confirm         # Paso 5: confirmar duelo y crear
      get :responsibility
      get :select_arena
      get :my_duels
    end
  
    member do
      patch :start
      patch :complete
      get :manage
      patch :randomize_teams
    end
  
    resources :lineups, only: [:index, :edit, :update, :destroy]
    resources :duel_goals, only: [:index, :new, :create, :destroy]
    resources :results, only: [:new, :create, :edit, :update]
  end

  # Arenas y Propietarios
    resources :arenas do
      resources :reservations, only: [:index, :new, :create], defaults: { reservable: 'Arena' }
      post :reserve, on: :member
    end

  resources :referees do
    resources :reservations, only: [:index, :new, :create], defaults: { reservable: 'Referee' }
  end  

  resources :callups, only: [] do
    post :send_callup, on: :collection
    collection do
      post :accept
      post :reject
    end
  end

  resources :owners, only: [:new, :create, :show]
  resources :reservations, only: [:index, :show]

  resources :challenges, only: [:create, :show] do
    member do
      patch :accept
      patch :reject
    end
  end

  # Namespace para administración
  namespace :admin do
    resources :clubs, only: [:index, :show, :edit, :update, :destroy]
    resources :clans, only: [:index, :show, :edit, :update, :destroy]
    resources :teams, only: [:index, :show, :edit, :update, :destroy]
    resources :duels, only: [:index, :show, :edit, :update, :destroy]
    resources :referees, only: [:index, :show, :edit, :update, :destroy]
    resources :arenas, only: [:index, :show, :edit, :update, :destroy]
  end

  # API pública
  namespace :api do
    namespace :v1 do
      resources :users, only: [:index, :show]
      resources :clubs, only: [:index, :show]
      resources :clans, only: [:index, :show]
      resources :teams, only: [:index, :show]
      resources :duels, only: [:index, :show]
      resources :referees, only: [:index, :show]
      resources :arenas, only: [:index, :show]
    end
  end

  # # Extras y errores
  # get 'dashboard', to: 'dashboard#index'
  # get 'search', to: 'search#index'
  # post 'search', to: 'search#results'
  # match '/404', to: 'errors#not_found', via: :all
  # match '/500', to: 'errors#internal_server_error', via: :all
  # match '*path', to: 'errors#not_found', via: :all
end