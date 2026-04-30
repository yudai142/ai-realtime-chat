Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # ========================================
  # Chapter 7: Health Check Endpoint
  # ========================================
  # Custom health check with DB and Redis connectivity
  get "healthz" => "health#status", as: :health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
  root "messages#index"
  resource :session, only: [:new, :create, :destroy]
  resources :messages, only: [:index, :create] do
    collection do
      post :stop
      post :regenerate
    end
  end
  mount ActionCable.server => "/cable"
  resources :conversations, only: [:edit, :update, :show]

  # 開発用ログイン
  if Rails.env.development?
    get "/dev/login", to: "dev#login"
  end
end
