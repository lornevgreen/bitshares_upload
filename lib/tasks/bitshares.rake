require 'open3'
namespace :bitshares do
  desc "Runs a python script and emails cloudcoin"
  task check_transactions: :environment do
  	account = "hello"
  	amount = 0
  	stdout_str, error_str, status = Open3.capture3('python3', Rails.application.credentials.bitshares_scripts[:transfer])
  	if status.success?
  	  stdout_json = JSON.parse(stdout_str.chomp.gsub("'", '"'))
      puts stdout_json
  	  # TODO: find ID
  	  return true
  	else
  	  # TODO:
      puts error_str 
  	  logger.warn {"Bitshares Transfer script execution failed."}
  	  logger.warn {error_str}
  	  return false
  	end
  end

end
