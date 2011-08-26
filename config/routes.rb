MeetlinkshareApi::Application.routes.draw do

  API_VERSION1="v1"
  namespace :v1 do
    resources :topics, :template_categories, :templates, :items, :bookmarks, :categories, :searches, :attachments, :custom_pages
  end
  devise_for 'v1/users', :controllers => { :sessions => "v1/sessions",:confirmations=>'v1/confirmations', :registrations=>"v1/registrations",:passwords=>'v1/passwords' } do
    post "v1/forgot_password", :to => "v1/passwords#create"
    post "v1/reset_password", :to => "v1/passwords#update"
    get "v1/user/:id", :to=>"v1/registrations#show"
    get "v1/users", :to=> "v1/registrations#index"
    get "users/confirmation",:to=>"v1/confirmations#show"
  end
  match "v1/item_topics/:id"=> 'v1/items#item_topics'
  match "v1/category_subcategories/:id" => 'v1/categories#subcategories'
  match "v1/category_items/:id" => 'v1/categories#items'
  match "v1/item_categories/:id" => 'v1/items#item_categories'
  match "v1/item_add_category" => 'v1/items#item_add_category'
  match "v1/item_add_attendees" => 'v1/items#item_add_attendees'
  match "v1/item_remove_attendees/:attendee_id" => 'v1/items#item_remove_attendees'
  match "v1/custom_page_fields" => 'v1/custom_pages#custom_page_fields'
  match "v1/custom_page_fields/:id" => 'v1/custom_pages#update_custom_page_fields',:via=>:put
  match "v1/custom_page_fields/:id" => 'v1/custom_pages#custom_page_fields_remove',:via=>:delete


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "v1/users#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end

