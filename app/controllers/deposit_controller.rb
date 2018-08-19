require 'net/http'
class DepositController < ApplicationController
  # GET  /deposit/index
  def index
  end

  # POST /deposit/upload
  # No View
  def upload
    # retrieve and validate params    
    # get account
    user_email = params["email"]
    # get bit shares account
    user_bitshares_account = params["bitshares_account"]
    # get uploaded file
    uploaded_io = params["cloud_coin_file"]

    # check if there was no email entered
    if user_email.blank?
      redirect_to deposit_index_url, alert: "Email is missing. Please try again."
      return
    elsif user_email.match(URI::MailTo::EMAIL_REGEXP).present? == false
      # check if the email is in valid format
      redirect_to deposit_index_url, alert: "Email is of invalid format. Please try again."
      return
    end

    # check if there was no bitshares account entered
    if user_bitshares_account.blank?
      redirect_to deposit_index_url, alert: "Bitshares account is missing. Please try again."
      return
    end

    # check if there was no file selected
    if uploaded_io.blank?
      redirect_to deposit_index_url, alert: "Stack file is missing. Please try again."
      return
    end

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
    
    # Get the file content
    uploaded_io_content = File.read(uploaded_io_full_path)

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
      
      if (status == "error")
        # if the status is "error", redirect to deposit
        error_msg = response_json["message"]
        error_msg = "The uploaded file was not a valid stack file or there was an unknown error."
        # remove the uploaded file
        FileUtils.remove_file(uploaded_io_full_path, force: true)
        redirect_to deposit_index_url, alert: error_msg
        return
      else
        # status should be "importing"
        # get the receipt id from the response and redirect to deposit_completed
        receipt_id = response_json["receipt"]
        flash[:notice] = "Your authentic coins will be uploaded to Bitshares shortly. We will send you an email notification to " + user_email
        # remove the uploaded file
        FileUtils.remove_file(uploaded_io_full_path, force: true)
        redirect_to controller: "deposit", action: "completed", receipt: receipt_id, email: user_email
        return
      end
    else
      # if uploaded file is NOT a cloudcoin stack file
      # remove the uploaded file
      FileUtils.remove_file(uploaded_io_full_path, force: true)
      redirect_to deposit_index_url, alert: "Uploaded file is not a valid stack file or there was an unknown error. Please try again."
    end
  end

  # GET  /deposit/completed
  def completed
  end
end
