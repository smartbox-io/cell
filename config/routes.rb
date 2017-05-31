Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :objects, only: %i(create), param: :uuid do
        member do
          resource :download, only: :show, controller: "objects/downloads"
        end
      end
    end
  end
end
