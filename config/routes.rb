Pig::Engine.routes.draw do
  # TODO: Allow this namespace to be defined in the Pig configuration

  root 'front/content_packages#home'

  scope '/admin' do
    devise_for :users, class_name: 'Pig::User', module: :devise, controllers: {
      sessions: 'pig/admin/sessions',
      passwords: 'pig/admin/passwords'
    }
  end

  namespace 'admin' do
    root 'content_types#dashboard'

    get 'not-authorized' => 'application#not_authorized'

    resources :content_types, except: :show do
      resources :content_packages, only: :new
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

    resources :content_packages, except: :show do
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
    resources :redactor_image_uploads, only: [:index, :create]

    if Pig.configuration.tags_feature
      resources :tag_categories, path: :tags, except: [:show, :destroy]
    end
  end

  get '404' => 'errors#not_found',
      via: [:get, :post, :patch, :delete],
      as: 'not_found'

  get '//*path', to: 'front/content_packages#show', as: 'content_package'
end
