require "sidekiq/web"

Rails.application.routes.draw do
  get "v1/health", to: "health#show"

  namespace :v1 do
    resources :conteudos, only: [:index, :show, :create]
  end

  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?
end
