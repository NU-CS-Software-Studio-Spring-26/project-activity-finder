Rails.application.routes.draw do
  root "activities#index"

  resources :users, only: [ :new, :create, :show, :edit, :update, :destroy ]
  resources :activities do
    member do
      post :join
      delete :leave
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get  "/login",  to: "sessions#new"
  post "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get "/signup", to: "users#new"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/terms",   to: "pages#terms",   as: :terms
  get "/privacy",  to: "pages#privacy",  as: :privacy
  get "/about",    to: "pages#about",    as: :about

  namespace :advisor do
    resource :messages, only: :create
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
