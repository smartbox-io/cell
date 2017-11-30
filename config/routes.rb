require "sidekiq/web"

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :objects, only: :create, param: :uuid do
        member do
          resource :download, only: :show, controller: "objects/download"
        end
      end
    end
  end
  namespace :cluster_api, path: "cluster-api" do
    namespace :v1 do
      resources :objects, only: [], param: :uuid do
        member do
          resource :download, only: :show, controller: "objects/download"
        end
      end
    end
  end
  namespace :admin_api, path: "admin-api" do
    namespace :v1 do
      resources :objects, only: :create, param: :uuid
      resource :volumes, only: %i[show update]
    end
  end
  mount Sidekiq::Web => "/sidekiq" unless Rails.env.production?
end
