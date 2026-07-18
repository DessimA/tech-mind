Rails.application.routes.draw do
  # Health check
  get "health", to: "health#show"

  # Web routes — controllers em app/controllers/web/ (Web:: namespace)
  scope module: :web do
    get  "login",    to: "sessions#new"
    post "login",    to: "sessions#create"
    get  "register", to: "registrations#new"
    post "register", to: "registrations#create"
    post "logout",   to: "sessions#destroy"

    resources :conteudos, only: [:index, :show, :new, :create]
  end

  # Health check via API path
  get "v1/health", to: "health#show"

  # API routes — controllers em app/controllers/api/v1/ (Api::V1:: namespace)
  namespace :api do
    namespace :v1 do
      resources :conteudos, only: [:index, :show, :create]
    end
  end

  # Raiz
  root to: redirect("/conteudos")
end
