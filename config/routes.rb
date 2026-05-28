Rails.application.routes.draw do
  # Health check (keep early for load balancers)
  get "up" => "rails/health#show", as: :rails_health_check

  # OmniAuth: POST /auth/google_oauth2 is handled by Rack middleware (see config/initializers/omniauth.rb).
  # These routes are the callback return from Google and OmniAuth failure redirects.
  match "/auth/:provider/callback",
        to: "sessions#omniauth",
        via: %i[get post],
        as: :omniauth_callback
  get "/auth/failure", to: "sessions#omniauth_failure", as: :omniauth_failure

  # Stable helper for views (middleware still owns the actual POST).
  direct(:google_oauth_authorize) { "/auth/google_oauth2" }

  root "activities#index"

  resources :users, only: %i[new create show edit update destroy]
  resources :activities do
    member do
      post :join
      delete :leave
      get :export_pdf
    end
  end

  get "/join/:token", to: "activities#join_via_token", as: :join_activity_via_token

  get  "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get "/signup", to: "users#new"
  get "/signup/check_email", to: "users#check_email", as: :check_email_signup

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "/terms", to: "pages#terms", as: :terms
  get "/privacy", to: "pages#privacy", as: :privacy
  get "/about", to: "pages#about", as: :about

  namespace :advisor do
    resource :messages, only: :create
  end
end
