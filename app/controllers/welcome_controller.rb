class WelcomeController < ApplicationController
  def index
  end

  def review
  end

  def upload
	uploaded_io = params["cloud_coin_file"]
	File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
		file.write(uploaded_io.read)
	end
	redirect_to welcome_review_url
  end
end
