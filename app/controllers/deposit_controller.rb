require 'net/http'
require 'open3'

class DepositController < ApplicationController
  before_action :set_email, only: [:upload, :completed]
  before_action :set_bitshares_account, only: [:upload, :completed]
  before_action :set_uploaded_io, only: [:upload]

  before_action :set_receipt_id, only: [:completed]

  # GET  /deposit/index
  def index
  end

  # POST /deposit/upload
  # No View
  # - Validates fields submitted via form
  # - Saves uploaded file on disk to /storage/upload 
  # - Sends file to online depository via deposit one stack
  # - Removes file from local disk
  # - Gets a receipt id from deposit one stack service
  # - Gets full receipt from get receipt service
  # - Calculates value of uploaded cloud coins
  # - Calls the Issue bitshares service with the account name and amount
  # - Sends an email
  # - If everything is successful redirects to completed
  def upload
    # Validations of params should have been done before this action started   
    # Save uploaded file on disk to /storage/upload 
    uploaded_io_full_path = save_stack_file(@uploaded_io)
    
    # Get the file content
    uploaded_io_content = File.read(uploaded_io_full_path)

    # Send file to online depository via deposit one stack
    # and get the receipt id
    receipt_id = send_to_depository(uploaded_io_content)

    # Remove the file from local disk
    FileUtils.remove_file(uploaded_io_full_path, force: true)

    # Do not proceed if receipt id is blank.
    # redirect_to called in send_to_depository
    if receipt_id.blank?
      logger.warn {"Receipt ID is blank"}
      return
    end

    # Get full receipt from get receipt service
    full_receipt = get_receipt_json(receipt_id)
    # Do not proceed if full_receipt is blank.
    # redirect_to called in send_to_depository
    if receipt_id.blank?
      logger.warn {"Receipt ID is blank"}
      return
    end

    # Calculate value of uploaded cloud coins
    deposit_amount = get_authentic_coins_value(full_receipt)

    # Call the Issue bitshares service with the account name and amount
    did_send = send_to_bitshares(@bitshares_account, deposit_amount)

    # Send an email to the user
    if deposit_amount > 0
      if did_send
        NotificationMailer.deposit_email(@email, @bitshares_account, deposit_amount).deliver_later
        flash[:notice] = "Your coins will be transferred to bitshares. An email has been sent to #{@email} for your records."
      else
        logger.warn {@email + " tried to upload " + deposit_amount.to_s + " CloudCoin(s) to bitshares account " + @bitshares_account}
        redirect_to deposit_index_url, alert: "Transfer failed! Your CloudCoins were lost"
        return
      end
    else
      logger.warn "nothing to transfer"
      logger.warn {@email + " has 0 CloudCoins to upload to their bitshares account, " + @bitshares_account + "."}
      flash[:alert] = "Nothing to transfer"
    end

    redirect_to controller: :deposit,
      action: :completed, 
      receipt_id: receipt_id,
      email: @email,
      bitshares_account: @bitshares_account
    
  end

  # GET  /deposit/completed
  def completed
    # Validations of params should have been done before this action started
    # get the JSON response from the Cloudcoin Get Receipt Service
    response_json = get_receipt_json(@receipt_id)

    # Check if the response is blank
    if response_json.blank?
      # If the response is blank, redirect to deposit
      redirect_to deposit_index_url, alert: "Something went wrong while checking the receipt. Please try again."
      return
    end

    # get the status of the receipt
    status = response_json["status"]
    
    # If the status is fail...
    if (status == "fail")
      # Redirect to deposit
      redirect_to deposit_index_url, alert: response_json["message"]
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
    @total_authentic_coins_value = get_authentic_coins_value(response_json)
  end


  private

  def set_email
    @email = params[:email]
    # check if there was no email entered
    if @email.blank?
      redirect_to deposit_index_url, alert: "Email is missing. Please try again."
    elsif @email.match(URI::MailTo::EMAIL_REGEXP).present? == false
      # check if the email is in valid format
      redirect_to deposit_index_url, alert: "Email is of invalid format. Please try again."
    end
  end
  def set_bitshares_account
    @bitshares_account = params[:bitshares_account]
    # check if there was no bitshares account entered
    if @bitshares_account.blank?
      redirect_to deposit_index_url, alert: "Bitshares account is missing. Please enter Bitshares account."
    else
      # Check if Bitshares account exists on Bitshares
      # Executing python script...
      # Retreiving the check account python script from the credentials
      stdout_str, error_str, status = Open3.capture3('python3', Rails.application.credentials.bitshares_scripts[:check_account], @bitshares_account)
      if !status.success?
        redirect_to deposit_index_url, alert: "Bitshares account does not exist."
      end      
    end
  end
  def set_uploaded_io
    @uploaded_io = params[:cloud_coin_file]
    # check if there was no file selected
    if @uploaded_io.blank?
      redirect_to deposit_index_url, alert: "Stack file is missing. Please try again."
    end
  end
  def set_receipt_id
    @receipt_id = params[:receipt_id]
    if @receipt_id.blank?
      redirect_to deposit_index_url, alert: "Receipt ID is blank. Please try again."
    end
  end
  def deposit_params    
    # params.require(:deposit).permit(:email, :bitshares_account, :cloud_coin_file)
  end

  ##
  # Saves the stack file to public/uploads
  # Uploaded file is renamed with the year, month, day and time 
  # prepended to the original file name. Goal is to generate a file
  # name that is unique.
  # @param    uploaded_io - ActionDispatch::Http::UploadedFile
  # @return   full path of saved stack file
  def save_stack_file(uploaded_io)
    # TODO: Generate a more secure filename
    # Generate a file name that will be unique YYYYMMSSuploadedfile.stack
    # Eg. 20180819163736_cc1.stack
    generated_file_name = Time.now.strftime("%Y%m%d%H%M%S") + "_" + uploaded_io.original_filename

    # TODO: check if the file already exists
    
    uploaded_io_full_path = Rails.root.join('storage', 'upload', generated_file_name)
    # Eg. uploaded_io_full_path is 
    # => #<Pathname:/home/dynamic/Desktop/workspace/bitshares_upload/public/uploads/20180819163736_cc1.stack>

    # Save the uploaded file to public/uploads
    File.open(uploaded_io_full_path, 'wb') do |file|
      file.write(uploaded_io.read)
    end

    return uploaded_io_full_path
  end

  def send_to_depository(uploaded_io_content)
    # https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html
    # http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
    # https://github.com/CloudCoinConsortium/CloudBank-V2#deposit-service
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

      # TODO: check if status is NIL
      
      if (status.blank?)
        redirect_to deposit_index_url, alert: "Status from Deposit One Stack is blank"
        return
      elsif (status == "error")
        # if the status is "error", redirect to deposit
        error_msg = response_json["message"]
        error_msg = "The uploaded file was not a valid stack file or there was an unknown error."
        redirect_to deposit_index_url, alert: error_msg
        return
      else
        # status should be "importing"
        # get the receipt id from the response and redirect to deposit_completed
        receipt_id = response_json["receipt"]
        # flash[:notice] = "Your authentic coins will be uploaded to Bitshares shortly. We will send you an email notification to " + user_email
        # redirect_to controller: "deposit", action: "completed", receipt: receipt_id, email: user_email
        if receipt_id.blank?
          redirect_to deposit_index_url, alert: "Receipt ID is blank"
        end
        return receipt_id
      end
    else
      # if uploaded file is NOT a cloudcoin stack file
      redirect_to deposit_index_url, alert: "Uploaded file is not a valid stack file or there was an unknown error. Please try again."
      return
    end
  end

  # Contacts Cloudcoin Get Receipt Service to receive the full receipt
  # https://github.com/CloudCoinConsortium/CloudBank-V2#get-receipt-service
  # GET https://bank.cloudcoin.global/service/get_receipt?rn=receipt_id&account=user_email
  # returns nil when server does not respond or 
  # returns JSON
  def get_receipt_json(receipt_id)
    # Check Receipt using Get Receipt Service
    # https://github.com/CloudCoinConsortium/CloudBank-V2#get-receipt-service
    uri = URI("https://bank.cloudcoin.global/service/get_receipt")
    params = { :rn => receipt_id, :account => Rails.application.credentials.cloudcoin[:account] }
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
      # TODO redirect to deposit index
      redirect_to deposit_index_url, alert: "Did not get a valid response from the get receipt service."
      return nil
    end
  end

  # Returns the total value of all the authentic coins
  # It iterates through the coins returned by get receipt service
  def get_authentic_coins_value(receipt_json)
    if receipt_json.blank? || receipt_json["receipt"].blank?
      return 0
    end

    total_value = 0
    receipt_json["receipt"].each do |coin|
      if coin.blank?
        return 0
      end
      if coin["status"] == "authentic"
        # get serial number
        serial_no = coin["sn"]

        case serial_no
        when 1..2097152 then total_value += 1
        when 2097153..4194304 then total_value += 5
        when 4194305..6291456 then total_value += 25
        when 6291457..14680064 then total_value += 100
        when 14680065..16777217 then total_value += 250
        end
      end
    end

    return total_value
  end

  ##
  # Sends Cloudcoin tokens to the given account
  # @param account - Account name in bitshares (String)
  # @param  amount - Amount that needs to be sent (Integer)
  # https://makandracards.com/makandra/44452-running-external-commands-with-open3
  # https://github.com/mx4492/simple_cmd/blob/master/lib/simple_cmd.rb
  # https://ruby-doc.org/stdlib-2.5.1/libdoc/open3/rdoc/Open3.html#method-c-capture3
  # 
  def send_to_bitshares(account, amount)
    stdout_str, error_str, status = Open3.capture3('python3', Rails.application.credentials.bitshares_scripts[:transfer], account, amount.to_s)
    if status.success?
      stdout_json = JSON.parse(stdout_str.chomp.gsub("'", '"'))
      # TODO: find ID
      return true
    else
      # TODO:
      logger.warn {"Bitshares Transfer script execution failed."}
      logger.warn {error_str}
      return false
    end
  end

  def old_send_to_bitshares(account, amount)
    if amount == 0
      return
    end
    # http://www.rubyinside.com/nethttp-cheat-sheet-2940.html    
    uri = URI.parse(Rails.application.credentials.cloudcoin[:issue_bitshares_url])
    params = { :amount => amount, :account => account }
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # TODO: remove when valid SSL cetificate is installed
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    # response.body
    # response.status
    if (response.code == "200")
      return true
    else
      redirect_to deposit_index_url, alert: "Invalid response from the Issue Bitshares service."
      return false
    end
  end
end
