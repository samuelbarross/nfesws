NfeSws::Application.routes.draw do

  resources :crons do
    collection do
      post :search, to: 'crons#index'
      get 'download_xml_retorno'
    end
  end

  resources :usuario_empresas

  devise_for :users

  resources :control_users, only: [:index, :edit, :update, :show, :destroy], as: :users

  resources :empresas do
    collection { post :search, to: 'empresas#index' }
  end

  resources :dominio_campos do
    collection { post :search, to: 'dominio_campos#index' }
  end

  resources :dominio_valores do
    collection { post :search, to: 'dominio_valores#index' }
  end

  resources :dominios do
    collection { post :search, to: 'dominios#index' }
  end

  resources :nota_duplicatas do
    collection { post :search, to: 'nota_duplicatas#index' }
  end

  resources :nota_produtos do
    collection { post :search, to: 'nota_produtos#index' }
  end

  resources :nota_fiscais do
    collection do
      post :search, to: 'nota_fiscais#index'
      post 'manifestacao_destinatario'
      get 'download_xml_nfe_sefaz'
      get 'download_xml_nfe'
      get 'download_danfe_nfe'
      post 'negar_nfe'
      # get 'consultarNfe'
      get :report, to: 'nota_fiscais#report_notas_fiscais'
      post :report, to: 'nota_fiscais#report_notas_fiscais'
      post :importar_nfe_xml, to: 'nota_fiscais#importar_nfe_xml'
      get :citacoes, to: 'nota_fiscais#citacoes'
      get :search_citacoes, to: 'nota_fiscais#citacoes'
      post :download_nfe_terceiro, to: 'nota_fiscais#download_nfe_terceiro'
    end
  end

  get "home/index"
  get "home/minor"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root to: 'home#index'
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
