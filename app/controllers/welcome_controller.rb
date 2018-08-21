require 'net/http'
class WelcomeController < ApplicationController

  # GET  /welcome/withdraw
  def withdraw
    # number of cloudcoins that need to be emailed to the user
    withdraw_amount = 1

    # get the email of the user
    email = "dipen.chauhan@protonmail.com"

    file_path = get_stack_file_path(withdraw_amount)
    if (file_path == nil)
      redirect_to welcome_withdraw_completed_url, alert: "Withdraw One Stack service did not respond as expected"
      return
    end
    NotificationMailer.download_email(email, file_path.to_s, withdraw_amount).deliver_later
    redirect_to welcome_withdraw_completed_url, notice: "completed"
  end

  # GET  /welcome/withdraw_completed
  def withdraw_completed
    
    render :json => { status: "202",
                      message: "Accepted. Email is being sent in the background" }
  end

  # GET  /welcome/summary
  def summary
    uri = URI("https://bank.cloudcoin.global/service/show_coins.aspx")
    params = {:pk => Rails.application.credentials.cloudcoin[:private_key], 
              :account => Rails.application.credentials.cloudcoin[:account]}
    uri.query = URI.encode_www_form(params)
    # Response
    res = ""
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new(uri)
      # Get the response
      res = http.request(req) # Net::HTTPResponse object
      # res.code should be 200
    end

    # Checking the response
    # res.code should be 200
    if (res.is_a?(Net::HTTPSuccess))
      response_json = JSON.parse(res.body)
      if (response_json["status"] == "fail")
        render status: 500, json: { 
          message: response_json["message"] 
        }.to_json
        return
      end

      render :json => { "1cc" => response_json["ones"], 
                        "5cc" => response_json["fives"],
                        "25cc" => response_json["twentyfives"],
                        "100cc" => response_json["hundreds"],
                        "250cc" => response_json["twohundredfifties"] }
    else
      render :json => { status: "500",
                        message: "Invalid response from Show Coins service" }
    end
  end

  private

  # Uses Cloudcoin Get Receipt Service
  # GET https://bank.cloudcoin.global/service/get_receipt?rn=receipt_id&account=user_email
  # returns nil when server does not respond or 
  # returns JSON
  def get_receipt_json(receipt_id, user_email)
    # Check Receipt using Get Receipt Service
    # https://github.com/CloudCoinConsortium/CloudBank-V2#get-receipt-service
    uri = URI("https://bank.cloudcoin.global/service/get_receipt")
    params = { :rn => receipt_id, :account => "depository" }
    uri.query = URI.encode_www_form(params)

    # Response
    res = ""
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new(uri)
      res = http.request(req) # Net::HTTPResponse object
      # res.code should be 200
    end

    # res.code should be 200
    if (res.is_a?(Net::HTTPSuccess))
      # Receive the JSON response and parse it
      response_json = JSON.parse(res.body)
      return response_json
    else
      return nil
    end
  end

  # Contacts the Withdraw One Stack service and requests Cloud Coins
  # The stack file is saved to /storage/download
  # Returns the file path of the stack file
  # GET https://bank.cloudcoin.global/service/withdraw_one_stack?amount=254&pk=ef50088c8218afe53ce2ecd655c2c786&account=CloudCoin@Protonmail.com
  def get_stack_file_path(withdraw_amount)
    uri = URI("https://bank.cloudcoin.global/service/withdraw_one_stack")
    params = {:amount => withdraw_amount, 
              :pk => Rails.application.credentials.cloudcoin[:private_key], 
              :account => Rails.application.credentials.cloudcoin[:account]}
    uri.query = URI.encode_www_form(params)

    # Response
    res = ""
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new(uri)
      # Get the response
      res = http.request(req) # Net::HTTPResponse object
      # res.code should be 200
    end

    # Checking the response
    # res.code should be 200
    if (res.is_a?(Net::HTTPSuccess))
      # Generate file name
      generated_file_name = Time.now.strftime("%Y%m%d%H%M%S") + "_" + withdraw_amount.to_s + ".CloudCoins.stack" 
      # Full file path
      download_io_full_path = Rails.root.join('storage', 'download', generated_file_name)

      # Format the response
      file_content_json = JSON.parse(res.body)
      file_content = JSON.pretty_generate(file_content_json)

      # Save the file
      File.open(download_io_full_path, 'w') { |file| file.write(file_content) }
      
      # TODO: check if file write was successful
      
      logger.info "Cloud coin file was saved"
      logger.debug file_content_json["cloudcoin"].size.to_s + " cloudcoin(s) saved in file " + generated_file_name

      return download_io_full_path
    else
      return nil
    end
  end

  # TODO
  def deposit_params
    params.require(:deposit).permit(:email, :bitshares_account, :cloud_coin_file)
  end

  # TODO
  def validate_params
  end
end
