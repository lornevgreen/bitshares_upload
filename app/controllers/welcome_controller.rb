require 'net/http'
class WelcomeController < ApplicationController
  # GET  /welcome/deposit
  def deposit
  end

  # GET  /welcome/deposit_completed
  def deposit_completed
    # Get receipt and email from params
    receipt_id = params["receipt"]
    user_email = params["email"]

    # Check if receipt and email params are blank
    if receipt_id.blank? || user_email.blank?
      redirect_to welcome_deposit_url, alert: "Something went wrong while checking the receipt. Please try again."
      return
    end

    # get the JSON response from the Cloudcoin Get Receipt Service
    response_json = get_receipt_json(receipt_id, user_email)

    # Check if the response is blank
    if response_json.blank?
      # If the response is blank, redirect to deposit
      redirect_to welcome_deposit_url, alert: "Something went wrong while checking the receipt. Please try again."
      return
    end

    # get the status of the receipt
    status = response_json["status"]
    
    # If the status is fail...
    if (status == "fail")
      # Redirect to deposit
      redirect_to welcome_deposit_url, alert: response_json["message"]
      return
    end
    
    # status is not fail...
    # Extract data from JSON
    @receipt_id = response_json["receipt_id"]
    @checked_at = response_json["time"]
    @total_authentic = response_json["total_authentic"]
    @total_fracked = response_json["total_fracked"]
    @total_counterfeit = response_json["total_counterfeit"]
    @total_lost = response_json["total_lost"]
    @coins = response_json["receipt"].compact
  end

  # POST /welcome/upload
  # No View
  def upload
    # get account
    user_email = params["email"]
    # get bit shares account
    user_bit_shares_account = params["bit_shares_account"]
    # get uploaded file
    uploaded_io = params["cloud_coin_file"]

    # check if there was no email entered
    if user_email.blank?
      redirect_to welcome_deposit_url, alert: "Email is missing. Please try again."
      return
    end

    # TODO check if the email is in valid format

    # TODO check if there was no bitshares account entered

    # check if there was no file selected
    if uploaded_io == nil || uploaded_io == ""
      redirect_to welcome_deposit_url, alert: "Stack file is missing. Please try again."
      return
    end

    # TODO: Generate a more secure filename
    # Generate a file name that will be unique YYYYMMSSuploadedfile.stack
    # Eg. 20180616CloudCoins.stack
    generated_file_name = Time.now.strftime("%Y%m%d%H%M%S") + "_" + uploaded_io.original_filename

    # TODO: check if the file already exists
    
    uploaded_io_full_path = Rails.root.join('storage', 'upload', generated_file_name)
    # Eg. uploaded_io_full_path is 
    # => #<Pathname:/home/dynamic/Desktop/workspace/bitshares-upload/public/uploads/201807051231401.CloudCoins.Counterfeit1.stack>

    # Save the uploaded file to public/uploads
    File.open(uploaded_io_full_path, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    
    # Get the file content
    uploaded_io_content = File.read(uploaded_io_full_path)

    # https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html
    # http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
    # We will be posting to the following URI
    uri = URI.parse("https://bank.cloudcoin.global/service/deposit_one_stack")
    
    # Response
    res = ""

    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(account: Rails.application.credentials.cloudcoin[:account], 
                        stack: uploaded_io_content)
      res = http.request(req)
      # res.code should be 200
    end

    if (res.is_a?(Net::HTTPSuccess))
      # if cloudcoin deposit one stack service was able to
      # process the request
      # 
      # Parse the JSON response
      response_json = JSON.parse(res.body)
      
      # get the status from the JSON response
      status = response_json["status"]
      
      if (status == "error")
        # if the status is "error", redirect to deposit
        error_msg = response_json["message"]
        if error_msg.blank?
          error_msg = "Uploaded file is not a valid stack file or there was an unknown error. Please try again."
        end
        redirect_to welcome_deposit_url, notice: error_msg
        return
      else
        # status should be "importing"
        # get the receipt id from the response and redirect to deposit_completed
        receipt_id = response_json["receipt"]
        flash[:notice] = "Your authentic coins will be uploaded to Bitshares shortly. We will send you an email notification to " + user_email
        redirect_to controller: "welcome", action: "deposit_completed", receipt: receipt_id, email: user_email
        return
      end
    else
      # if uploaded file is NOT a cloudcoin stack file
      redirect_to welcome_deposit_url, alert: "Uploaded file is not a valid stack file or there was an unknown error. Please try again."
    end
  end

  # GET  /welcome/withdraw
  def withdraw
    # number of cloudcoins that need to be emailed to the user
    withdraw_amount = 1

    # get the email of the user
    email = "get.dipen@gmail.com"

    file_path = get_stack_file_path(withdraw_amount)
    if (file_path == nil)
      redirect_to welcome_withdraw_completed_url, alert: "Withdraw One Stack service did not respond as expected"
      return
    end
    NotificationMailer.download_email(email, file_path, withdraw_amount)
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

  def email_stack_file(email, file_path, withdraw_amount)
    # TODO: Email stack file to user
  end
end
