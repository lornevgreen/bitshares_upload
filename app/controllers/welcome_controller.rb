class WelcomeController < ApplicationController
  def index
  end

  def review
    puts "****"
    sleep 5
    puts params.inspect
  end

  def upload
    uploaded_io = params["cloud_coin_file"]
    generated_file_name = Time.now.strftime("%Y%m%d%H%M%S") + uploaded_io.original_filename
    File.open(Rails.root.join('public', 'uploads', generated_file_name), 'wb') do |file|
      file.write(uploaded_io.read)
    end
    # File has been uploaded
    
    
    redirect_to controller: "welcome", action: "review", f: generated_file_name
  end
end
