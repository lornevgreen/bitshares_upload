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
    
    ct_logger.close
  end

  desc "Test task"
  task test: :environment do
    t = Time.now
    f = File.open("test.txt", 'a')
    f << t << "\n"
    f.close
  end
end
