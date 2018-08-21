# == Route Map
#
#                     Prefix Verb URI Pattern                                                                              Controller#Action
#                       root GET  /                                                                                        deposit#index
#              deposit_index GET  /deposit/index(.:format)                                                                 deposit#index
#          deposit_completed GET  /deposit/completed(.:format)                                                             deposit#completed
#             deposit_upload POST /deposit/upload(.:format)                                                                deposit#upload
#             withdraw_index GET  /withdraw/index(.:format)                                                                withdraw#index
#         withdraw_completed GET  /withdraw/completed(.:format)                                                            withdraw#completed {:format=>"json"}
#            welcome_deposit GET  /welcome/deposit(.:format)                                                               welcome#deposit
#  welcome_deposit_completed GET  /welcome/deposit_completed(.:format)                                                     welcome#deposit_completed
#             welcome_upload POST /welcome/upload(.:format)                                                                welcome#upload
#           welcome_withdraw GET  /welcome/withdraw(.:format)                                                              welcome#withdraw
# welcome_withdraw_completed GET  /welcome/withdraw_completed(.:format)                                                    welcome#withdraw_completed {:format=>"json"}
#            welcome_summary GET  /welcome/summary(.:format)                                                               welcome#summary {:format=>"json"}
#         rails_service_blob GET  /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
#  rails_blob_representation GET  /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#         rails_disk_service GET  /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
#  update_rails_disk_service PUT  /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#       rails_direct_uploads POST /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create

Rails.application.routes.draw do
	# You should put the root route at the top of the file, because it is 
	# the most popular route and should be matched first.
	#  The priority goes from top to bottom. The last route in that file 
	#  is at the lowest priority and will be applied last.
	root to: 'deposit#index'
	get 'deposit/index'
    get 'deposit/completed'
    post 'deposit/upload'

    get 'withdraw/index'
    get 'withdraw/completed', defaults: {format: 'json'}

    # Old routes:
	# get 'welcome/deposit'
	# get 'welcome/deposit_completed'
	# post 'welcome/upload'

	# get 'welcome/withdraw'
	# get 'welcome/withdraw_completed', defaults: {format: 'json'}

	get 'welcome/summary', defaults: {format: 'json'}
  
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
