Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :scenarios, only: [ :index, :show ]

  namespace :manage do
    resources :scenarios
    resources :game_systems, except: [ :show ]
    resources :authors, except: [ :show ]
  end

  # sitemap_generator の出力を tmp から配信する。
  get "sitemap.xml", to: "sitemaps#show", defaults: { format: "xml" }

  root "scenarios#index"
end
