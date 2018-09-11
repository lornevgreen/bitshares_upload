require 'open3'
namespace :bitshares do
  desc "Runs a python script and emails cloudcoin"
  task check_transactions: :environment do
    withdraw_logger = Logger.new('log/withdraw.log', 10, 1024000)
    stdout_str, stderr_str, status = Open3.capture3('python3', "../python-bitshares/account_balances.py")
    if status.success?
      puts stdout_str
      withdraw_logger.info {stdout_str}
    else
      withdraw_logger.fatal {"Could not execute Python script"}
      withdraw_logger.fatal {stderr_str}
    end
    withdraw_logger.close
  end
end
