require 'open3'
require 'benchmark'
namespace :bitshares do
  desc "Runs a python script and emails cloudcoin"
  task check_transactions: :environment do
    ct_logger = Logger.new('log/check_transactions.log', 10, 1024000)
    ct_logger.info {"===Starting check_transactions==="}

    last_withdraw_transaction = ""
    # Check if the last transaction file exists
    if (File.exist?(Rails.root.join('storage', 'last_withdraw.txt')))
      last_withdraw_transaction = File.read(Rails.root.join('storage', 'last_withdraw.txt'))
      ct_logger.info {"Found last_withdraw.txt. Last Withdraw Transaction: #{last_withdraw_transaction}."}
    else
      ct_logger.info {"last_withdraw.txt not found."}
    end

    ct_logger.info {"===Calling Python Script==="}
    
    transactions_json = ""
    time_to_run = Benchmark.measure {
      stdout_str, stderr_str, status = Open3.capture3('python3', "../python-bitshares/check_transactions.py", last_withdraw_transaction)
      if status.success?
        puts stdout_str
        ct_logger.debug {stdout_str}
        # Parse JSON
        transactions_json = JSON.parse(stdout_str)
      else
        ct_logger.fatal {"Could not execute Python script"}
        ct_logger.fatal {stderr_str}
      end
    }
    puts "Time taken to run Python script: #{time_to_run.real}"
    ct_logger.info {"Time taken to run Python script: #{time_to_run.real}"}

    if transactions_json != ""
      # Iterate through the json in reverse because
      # the oldest transactions need to be processed first
      transactions_json.reverse_each { |tj|
        # Transaction ID
        t_id = tj["id"]
        t_from = tj["from"]
        t_to = tj["to"]
        t_amount = tj["amount"]
        t_currency = tj["currency"]
        t_memo = tj["memo"]
        puts "#{t_id}: #{t_from}=>#{t_to} #{t_amount} #{t_currency} #{t_memo}"
        ct_logger.info {"Processing transaction #{t_id}: #{t_from}=>#{t_to} #{t_amount} #{t_currency} #{t_memo}"}
        # TODO: Download Stack File
        # stack_file_path = download_stack_file(t_amount)
        # TODO: Email Stack File
        # TODO: Write to last_withdraw.txt
      }
    else
      ct_logger.info {"Python Script output could not be parsed."}
    end
    
    ct_logger.close
  end

  desc "Test task"
  task test: :environment do
    t = Time.now
    f = File.open("test.txt", 'a')
    f << t << "\n"
    f.close
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
      
      logger.info "Cloud coin file was saved"
      logger.debug file_content_json["cloudcoin"].size.to_s + " cloudcoin(s) saved in file " + generated_file_name

      return download_io_full_path
    else
      return nil
    end
  end
end
