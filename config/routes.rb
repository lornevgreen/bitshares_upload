# == Route Map
#
#                    Prefix Verb URI Pattern                                                                              Controller#Action
#                      root GET  /                                                                                        welcome#index
#             welcome_index GET  /welcome/index(.:format)                                                                 welcome#index
#            welcome_review GET  /welcome/review(.:format)                                                                welcome#review
#            welcome_upload POST /welcome/upload(.:format)                                                                welcome#upload
#        rails_service_blob GET  /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
# rails_blob_representation GET  /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#        rails_disk_service GET  /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
# update_rails_disk_service PUT  /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#      rails_direct_uploads POST /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create

Rails.application.routes.draw do
	# You should put the root route at the top of the file, because it is 
	# the most popular route and should be matched first.
	#  The priority goes from top to bottom. The last route in that file 
	#  is at the lowest priority and will be applied last.
	root :to => "welcome#index"
	get 'welcome/index'
	get 'welcome/completed'
	post 'welcome/upload'
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
