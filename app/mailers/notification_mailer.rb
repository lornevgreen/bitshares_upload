class NotificationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notification_mailer.download_file.subject
  #
  
  # Sends stack file to user
  # @param  email             stack file will be sent to this email   
  # @param  withdraw_amount   amount of cloud coins that are being sent
  # @param  file_path         filepath of the stack file  
  def download_email(email, file_path, withdraw_amount)
    @withdraw_amount = withdraw_amount
    attachments["cc" + withdraw_amount.to_s + ".stack"] = File.read(file_path)
    mail(to: email, subject: "Your Cloudcoins Can Be Downloaded")
  end
end
