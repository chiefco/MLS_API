MeetlinkshareApi::Application.routes.draw do

  API_VERSION1="v1"

  namespace :v1 do
    resources :topics, :template_categories, :templates, :items, :bookmarks, :categories, :searches, :attachments, :custom_pages,:tasks,:locations, :pages, :contacts,:comments,:communities, :shares, :folders
    match "/altitude" => 'locations#get_altitude',:via=>:get
    match "/location_names" => 'locations#location_names',:via=>:get
    match "item_add_attendees" => 'items#item_add_attendees',:via=>:post
    match 'get_page/:id', :to => 'items#get_page'
    match "item_topics/:id"=> 'items#item_topics'
    match "upcoming_meetings_count" => 'items#upcoming_meetings_count'
    match "category_subcategories/:id" => 'categories#subcategories'
    match "category_items/:id" => 'categories#items'
    match "items/:id/item_categories" => 'items#item_categories'
    match "item_add_category" => 'items#item_add_category'
    match "item_remove_attendees/:attendee_id" => 'items#item_remove_attendees'
    match "items/:id/list_item_attendees" => 'items#list_item_attendees'
    match "custom_page_fields" => 'custom_pages#custom_page_fields'
    match "custom_page_fields/:id" => 'custom_pages#update_custom_page_fields',:via=>:put
    match "custom_page_fields/:id" => 'custom_pages#custom_page_fields_remove',:via=>:delete
    match "reminders" => 'tasks#add_reminder',:via=>:post
    match "reminder/:id" => 'tasks#get_reminder',:via=>:get
    match "reminder/:id" => 'tasks#delete_reminder',:via=>:delete
    match "reminder/:id" => 'tasks#update_reminder',:via=>:put
    match "reminders/:task_id" => 'tasks#get_all_reminders'
    match "/item_tasks/:id" => 'items#get_all_tasks'
    match "/generic_search" => 'searches#search'
    match "/add_bookmark/:id" => 'bookmarks#add_bookmark'
    match "/remove_bookmark/:id" => 'bookmarks#remove_bookmark'
    match "/item/statistics" => 'items#get_statistics'
    match "/community_invite/:id" => 'communities#invite_member'
    match "/community_members/:id" => 'communities#members'
    match "/accept_invitation" => 'communities#accept_invitation'
    match "/remove_member" => 'communities#remove_member'
    match "/item_comments/:id" => 'items#comments'
    match "/topic_comments/:id" => 'topics#comments'
    match "/invite_member" => 'contacts#invite_member'
    match "/change_role" => 'communities#change_role'
    match "/share_item" => 'contacts#share'
    match "/remove_share/:id" => 'contacts#remove_share'
    match "/shares/:id" => 'contacts#shares'
    match "/items/pages/:item_id" => 'pages#index'
    match "/items/:item_id/tasks" => 'items#tasks'
    match "/multiple_delete" => 'communities#multiple_delete'
    match "/attachments_multiple_delete" => 'attachments#attachments_multiple_delete'
    match "attachment_update" => "attachments#attachment_update"
    match "/invite_from_community" => 'communities#invite_from_community', :via => :post
    match "/member_delete" => "communities#member_delete"
    match "/attachments_download" => 'attachments#attachments_download'
    match "/folder_tree" => 'folders#folder_tree'
    match "/move_attachments" => 'folders#move_attachments'
    match '/move_multiple_attachments', :to=>'folders#move_multiple_attachments'
    match '/move_folders', :to=>'folders#move_folders'
    match '/get_file_revisions/:id', :to => 'attachments#get_revisions'
    match '/restore_file/:id', :to => 'attachments#restore_file'      
    match '/validate_attachment', :to => 'attachments#validate_attachment'
    match '/shares_multiple_delete', :to => 'shares#shares_multiple_delete'
    match '/multiple_member_delete', :to => 'communities#multiple_member_delete'
    match '/remove_shared_team', :to => 'communities#remove_shared_team'
    match '/file_notifications', :to => 'shares#file_notifications'
    match '/subscribe_status', :to => 'communities#subscribe_status'
    match '/add_page_comment', :to => 'items#add_page_comment'
  end

  devise_for 'users',:controllers => { :sessions => "v1/sessions",:confirmations=>'v1/confirmations', :registrations=>"v1/registrations",:passwords=>'v1/passwords' } do
    post "v1/forgot_password", :to => "v1/passwords#create"
    post "v1/users/sign_in", :to => "v1/sessions#create"
    post "v1/users", :to => "v1/registrations#create"
    put "v1/user", :to => "v1/registrations#update"
    post "v1/reset_password", :to => "v1/passwords#update"
    get "v1/user", :to=>"v1/registrations#show"
    get "v1/users", :to=> "v1/registrations#index"
    get "users/confirmation",:to=>"v1/confirmations#show"
    delete "v1/close_account",:to=>'v1/registrations#close_account'
    get "v1/industries",:to=>'v1/registrations#options_for_the_field'
    get "v1/activities",:to=>'v1/registrations#activities'
    post "v1/synchronisation",:to=>'v1/sessions#synchronisation'
    post "v1/community_synchronisation", :to => 'v1/sessions#community_synchronisation'
    get "v1/image",:to=>'v1/sessions#get_image'
  end

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

