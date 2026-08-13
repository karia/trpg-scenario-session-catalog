Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # 開始は POST 限定（omniauth-rails_csrf_protection）。コールバックは Google からの GET。
  match "/auth/:provider/callback", to: "sessions#create", via: [ :get, :post ],
    constraints: { provider: /google_oauth2/ }
  get "/auth/failure", to: "sessions#failure"
  resource :session, only: [ :destroy ]
  resource :registration, only: [ :new ]

  resources :scenarios do
    resource :favorite, only: [ :create, :destroy ]
    resource :spoiler_reveal, only: [ :create, :destroy ]
    post :refresh_booth_image, on: :member
    delete :jacket, on: :member, action: :destroy_jacket
  end
  resources :scenario_order, only: [ :index ], controller: :scenario_order do
    patch :reorder, on: :collection
    patch :move, on: :member
  end
  resources :play_sessions
  resources :people
  resources :game_systems
  resources :authors

  namespace :manage do
    resources :groups, except: [ :new ]
    resources :users, only: [ :index, :show, :edit, :update ]
    resource :site_setting, only: [ :show, :edit, :update ]
  end

  # sitemap_generator の出力を tmp から配信する。
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: "xml" }

  root "scenarios#index"
end
