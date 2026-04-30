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
  # Chapter 9-3: Root changed to conversations#index
  root "conversations#index"
  
  resource :session, only: [:new, :create, :destroy]
  
  # Chapter 9: Multiple conversations management
  resources :conversations, only: [:index, :show, :create, :edit, :update, :destroy] do
    member do
      post :retitle
      get :preset
      get  :export     # エクスポート
      post :share      # 共有リンク発行
      post :archive    # アーカイブ
    end
  end

  # Chapter 10: 共有リンク（署名トークン）
  get "/s/:token", to: "shares#show", as: :shared_conversation
  
  resources :messages, only: [:index, :create] do
    collection do
      post :stop
      post :regenerate
    end
  end
  
  mount ActionCable.server => "/cable"

  # 開発用ログイン
  if Rails.env.development?
    get "/dev/login", to: "dev#login"
  end
end
