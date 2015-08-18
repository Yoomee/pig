Pig::Engine.routes.draw do
  root 'content_types#dashboard'

  get 'not-authorized' => 'application#not_authorized'

  devise_for :users, class_name: 'Pig::User', module: :devise, controllers: {
    sessions: 'pig/sessions',
    passwords: 'pig/passwords'
  }

  resources :content_types, except: :show do
    resources :content_packages, :only => :new
    member do
      get 'children'
      get 'duplicate'
      get 'reorder'
      put 'reorder' => 'content_types#save_order'
    end
  end

  namespace :manage do
    resources :users do
      member do
        post :set_active
        post :deactivate
        get :content
      end
    end
  end

  get '/content' => 'content_types#dashboard'
  post '/attachments' => 'attachments#create'

  resources :content_packages do
    collection do
      get 'filter/:filter' => 'content_packages#index', :as => 'filter'
      get 'deleted'
      get 'activity'
      get 'search'
    end
    member do
      get 'children'
      put 'delete'
      get 'reorder'
      put 'save_order'
      put 'restore'
      get 'activity'
      post 'upload_sir_trevor_attachment'
      patch 'ready_to_review'
      get 'analytics'
    end
  end

  resources :navigation_items do
    collection do
      get 'reorder'
      put 'reorder' => 'navigation_items#save_order'
      get :search
    end
    member do
      get 'reorder'
      put 'reorder' => 'navigation_items#save_order'
    end
  end

  resources :personas
  resources :meta_data
  resources :redactor_image_uploads, :only => [:index, :create]

  if Pig::configuration.tags_feature
    resources :tag_categories, path: :tags, except: [:show, :destroy]
  end

end

Rails.application.routes.draw do
  get '/content_package/:id' => 'pig/content_packages#show'
  get '/content_packages/:id' => 'pig/content_packages#show'
  Pig::ContentPackage.member_routes.each do |route|
    send(route[:method], route[:route].present? ? "*path/#{route[:route]}" : "*path" , to: "pig/content_packages##{route[:action]}")
  end
end
