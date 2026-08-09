Rails.application.routes.draw do
  # Avo は Phase 1 で保護を付けてから mount_avo する。
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "up" => "health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
