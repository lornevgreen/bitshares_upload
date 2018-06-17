require 'net/http'
class WelcomeController < ApplicationController
  def index
  end

  def review

  end

  def upload
    uploaded_io = params["cloud_coin_file"]
    # Generate a file name that will be unique YYYYMMSSuploadedfile.stack
    # Eg. 20180616CloudCoins.stack
    generated_file_name = Time.now.strftime("%Y%m%d%H%M%S") + uploaded_io.original_filename
    File.open(Rails.root.join('public', 'uploads', generated_file_name), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    # File has been saved
    
    uploaded_file_content = File.read(Rails.root.join('public', 'uploads', generated_file_name))
    
    # https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html
    uri = URI.parse("https://bitshares.cloudcoin.global/deposit_one_stack.aspx")
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Post.new(uri)
      req.set_form_data("stack" => uploaded_file_content)
      res = http.request(req)
      # response.code should be 200
      if (res.code == "200")
        response_json = JSON.parse(res.body)
        receipt = response_json["receipt"]
      end
    end  

    redirect_to controller: "welcome", action: "review", f: generated_file_name
  end
end
