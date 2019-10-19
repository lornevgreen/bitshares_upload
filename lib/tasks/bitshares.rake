require 'open3'
require 'benchmark'
require 'net/http'
namespace :bitshares do
  desc "Runs a python script and emails cloudcoin"
  task check_transactions: :environment do
    ct_logger = Logger.new('log/check_transactions.log', 10, 1024000)
    cte_logger = Logger.new('log/check_transactions_error.log', 10, 1024000)
    # ct_logger.info {"===STARTED check_transactions==="}

    last_withdraw_transaction = ""
    # Check if the last transaction file exists
    if (File.exist?(Rails.root.join('storage', 'last_withdraw.txt')))
      last_withdraw_transaction = File.read(Rails.root.join('storage', 'last_withdraw.txt'))
    else
      ct_logger.info {"last_withdraw.txt not found."}
    end

    
    transactions_json = ""
    time_to_run = Benchmark.measure {
      stdout_str, stderr_str, status = Open3.capture3('python3', "../python-bitshares/check_transactions.py", last_withdraw_transaction)
      if status.success?
        # Parse JSON
        transactions_json = JSON.parse(stdout_str)
      else
        ct_logger.fatal {"Could not execute Python script"}
        ct_logger.fatal {stderr_str}
      end
    }
    # ct_logger.info {"Time taken to run Python script: #{time_to_run.real}"}

    if transactions_json != ""
      # Iterate through the json in reverse because
      # the oldest transactions need to be processed first
      ct_logger.info {"Transactions found: #{transactions_json.size}"}
      transactions_json.reverse_each { |tj|
        # Transaction ID
        t_id = tj["id"]
        t_from = tj["from"]
        t_to = tj["to"]
        t_amount = tj["amount"]
        t_currency = tj["currency"]
        t_memo = tj["memo"]
        ct_logger.info {"Processing transaction #{t_id}: #{t_from}=>#{t_to} #{t_amount} #{t_currency} #{t_memo}"}
        
        # Checking Amount
        t_amount_new = t_amount.to_i
        if (t_amount_new > 0)
          # Checking Currency
          if (t_currency == "CLOUDCOIN")
            # Check if memo exists
            if (t_memo.blank?) || !(URI::MailTo::EMAIL_REGEXP.match(t_memo))
              ct_logger.info {"Memo/Email: #{t_memo} (INVALID)"}
              ct_logger.info {"Default Email: dipen.chauhan@protonmail.com"}
              t_memo = "dipen.chauhan@protonmail.com"
            end
            # Download Stack File
            stack_file_path = download_stack_file(t_amount_new)
            ct_logger.info {"Downloaded file to #{stack_file_path.to_s}"}
            
            # Write to last_withdraw.txt
            File.write(Rails.root.join('storage', 'last_withdraw.txt'), t_id.split(".").last)

            # Email Stack File
            NotificationMailer.download_email(t_from, t_memo, stack_file_path.to_s, t_amount_new).deliver_now
            ct_logger.info {"Emailed: #{t_memo} Amount: #{t_amount_new}"}
            
            # Delete the stack file
            # File.delete(stack_file_path)
          else
            ct_logger.error {"Currency: #{t_currency} (INVALID)"}
            ct_logger.error {"Skipping transaction"}
            cte_logger.error {"#{t_id}: #{t_from}=>#{t_to} Amount: #{t_amount_new} Currency: #{t_currency} (INVALID)"}
            File.write(Rails.root.join('storage', 'last_withdraw.txt'), t_id.split(".").last)
          end
        else
          ct_logger.error {"Amount: #{t_amount} (INVALID)"}
          ct_logger.error {"Skipping transaction"}
          cte_logger.error {"#{t_id}: #{t_from}=>#{t_to} Amount: #{t_amount} (INVALID)"}
          File.write(Rails.root.join('storage', 'last_withdraw.txt'), t_id.split(".").last)
        end
      }
    else
      ct_logger.error {"Python Script output could not be parsed."}
    end
    
    ct_logger.close
    cte_logger.close
  end

  desc "Manual Send"
  task manual_send: :environment do
    # t_amount_new = 628179
    t_amount_new = 1
    t_from = "dc366" # accout name on bitshares
    t_memo = "dipen.chauhan@protonmail.com" # email of recipient

    # Download Stack File
    stack_file_path = download_stack_file(t_amount_new)
    # Email Stack File
    NotificationMailer.download_email(t_from, t_memo, stack_file_path.to_s, t_amount_new).deliver_now
    # NotificationMailer.download_email(t_from, t_memo, stack_file_path.to_s, t_amount_new).deliver_now
  end

  desc "Test Email"
  task test_email: :environment do
    NotificationMailer.deposit_email("dipen.chauhan@protonmail.com", "dc366", 10).deliver_now
  end

  # Contacts the Withdraw One Stack service and requests Cloud Coins
  # The stack file is saved to /storage/download
  # Returns the file path of the stack file
  # GET https://bank.cloudcoin.global/service/withdraw_one_stack?amount=254&pk=ef50088c8218afe53ce2ecd655c2c786&account=CloudCoin@Protonmail.com
  def download_stack_file(withdraw_amount)
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
      
      # logger.info "Cloud coin file was saved"
      # logger.debug file_content_json["cloudcoin"].size.to_s + " cloudcoin(s) saved in file " + generated_file_name

      return download_io_full_path
    else
      return nil
    end
  end
end
