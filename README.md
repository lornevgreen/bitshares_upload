# BITSHARES UPLOAD

Deposit
- Send .stack file to depository
- Send message/memo to Bitshares Wallet
- Wallet distributes token to end user

Withdraw
- Wallet Receives tokens
- Message to CloudBank
- Send .stack to end user

## IP Address
13.232.170.28

## Configuration and System Dependencies
- Ubuntu 16.04 LTS
- ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]
- Rails 5.2.1
- Create directories:
	- /storage/upload
	- /storage/download

## Paths
/ or /deposit - Upload Files

## CloudCoin Services Reference

Print Welcome:
```GET https://bank.cloudcoin.global/service/print_welcome```

Echo Service: 
```GET https://bank.cloudcoin.global/service/echo?account=CloudCoin@Protonmail.com&pk=00000000000000000000000000000000```

Deposit Service:
```bash
POST https://bank.cloudcoin.global/service/deposit_one_stack

account=CloudCoin@Protonmail.com
stack=
{
	"cloudcoin": [
		{ 
		"nn":"1", 
		"sn":"1112240", 
		"an": ["f5a52ee881daaae548c24a8eaff7176c", "415c2375a6fa48c4661f5af8d7c95541", "73e067b7b47c1556deebdca33f9a09fb", "9b90d265d102a565a702813fa2211f54", "e3e191ca987c8010a3adc49c6fc18417",
			"baa7578e207b7cfaa0b8336d7ed4a4f8", "6d8a5c66a589532fe9e5dc3932650cfa", "1170b354e097f2d90132869631409bd3", "b7bc83e8ee7529ff9f874866b901cf15", "a37f6c4af8fbcfbc4d77880fc29ddfbc",
			"277668208e9bafd9393aebd36945a2c3", "ef50088c8218afe53ce2ecd655c2c786", "b7bbb01fbe6c3a830a17bd9a842b46c0", "737360e18596d74d784f563ca729aaea", "e054a34f2790fd3353ea26e5d92d9d2f",
			"7051afef36dc388e65e982bc853be417", "ea22cbae0394f6c6918691f2e2f2e267", "95d1278f54b5daca5898c62f267b6364", "b98560e11b7142d1addf5b9cf32898da", "e325f615f93ed682c7aadf6b2d77c17a",
			"3e8f9d74290fe31d416b90db3a0d2ab1", "c92d1656ded0a4f68e5171c8331e0aea", "7a9cee66544934965bca0c0cb582ba73", "7a55437fa98c1b10d7f47d84f9accdf0", "c3577cced2d428f205355522bc1119b6"],
		"ed":"7-2019",
		"pown":"ppppppppppppppppppppppppp",
		"aoid": []
		}

	]
}

```

Get Receipt Service:
```GET https://bank.cloudcoin.global/service/get_receipt?rn=ef50088c8218afe53ce2ecd655c2c786&account=CloudCoin@Protonmail.com```

Show Coins: 
```GET https://bank.cloudcoin.global/service/show_coins?pk=00000000000000000000000000000000&account=CloudCoin@Protonmail.com```

## How to Connet to Your Remote Server?
- Shortcuts to SSH clients - https://askubuntu.com/questions/754450/shortcuts-to-ssh-clients
- How To Configure SSH Key-Based Authentication on a Linux Server - https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server

## Deployment Instructions
- Nameserver (if needed): https://support.rackspace.com/how-to/changing-dns-settings-on-linux/
- Setup Ruby On Rails on Ubuntu 16.04 - https://gorails.com/setup/ubuntu/16.04
- Installing Passenger + Nginx on Ubuntu 16.04 LTS - https://www.phusionpassenger.com/library/install/nginx/install/oss/xenial/
- Deploying a Ruby app on a Linux/Unix production server - https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/nginx/oss/xenial/deploy_app.html
- Change Client Max Body Size: https://serverfault.com/questions/814767/413-request-entity-too-large-in-nginx-with-client-max-body-size-set
- Deploying application updates - https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/nginx/oss/deploy_updates.html
```
git pull
bundle install --deployment --without development test
bundle exec rake assets:precompile db:migrate RAILS_ENV=production
```
- Restart Services:
```sh
passenger-config restart-app $(pwd)
sudo service nginx restart
```

## Nginx configuration file
File: /etc/nginx/sites-enabled/bitshares_upload.conf
```
server {
    listen 80;
    server_name sell.cloudcoin.global;

    # Tell Nginx and Passenger where your app's 'public' directory is
    root /var/www/bitshares_upload/code/public;

    # set client body size to 20M #
    client_max_body_size 20M;

    # Turn on Passenger
    passenger_enabled on;
    passenger_ruby /home/dynamic/.rvm/gems/ruby-2.5.1/wrappers/ruby;
}
```

## Using SSL with Passenger in Production

- Certbot - https://certbot.eff.org/lets-encrypt/ubuntuxenial-nginx
`
$ sudo apt-get update
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository ppa:certbot/certbot
$ sudo apt-get update
$ sudo apt-get install python-certbot-nginx
$ sudo certbot --nginx
`
- Test SSL - https://www.ssllabs.com/ssltest/analyze.html?d=www.site.com

## NGINX and Passenger Debug
- service nginx configtest
- /usr/sbin/nginx -t


## References
- HTTPS
	- https://blog.benroux.me/production-https-rails-app-using-nginx-and-lets-encrypt/
	- https://www.techrepublic.com/article/how-to-set-dns-nameservers-in-ubuntu-server-18-04/
	- https://mozilla.github.io/server-side-tls/ssl-config-generator/
	- https://gorails.com/guides/free-ssl-with-rails-and-nginx-using-let-s-encrypt
	- https://www.phusionpassenger.com/library/deploy/nginx/prod_ssl.html
	- https://gist.github.com/rkjha/d898e225266f6bbe75d8
- Pstore
	- https://robm.me.uk/ruby/2014/01/25/pstore.html
	- https://apidock.com/ruby/PStore
- Spinners:
	- https://github.com/yangshun/awesome-spinners
	- https://codepen.io/nikhil8krishnan/pen/rVoXJa
	- http://samherbert.net/svg-loaders/
	- https://codepen.io/overdrivemachines/pen/ZMQGPp
	- https://loading.io/
- DKIM: 
	- https://www.stefanwienert.de/blog/2013/06/20/send-bulk-e-mails-safely-with-spf-and-dkim-with-rails/
	- https://github.com/tomas/tuktuk
	- https://help.campaignmonitor.com/manage-your-own-authentication
	- https://www.sparkpost.com/blog/dkim-validation/
	- https://docs.aws.amazon.com/ses/latest/DeveloperGuide/dkim.html
	- https://shapeshed.com/getting-email-through-spam-filters-from-a-rails-app/
- https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html
- Gem Permissions Fix: https://stackoverflow.com/a/37842339/1553074
- Cloud Bank: https://github.com/CloudCoinConsortium/CloudBank-V2
- Credentials: https://medium.com/cedarcode/rails-5-2-credentials-9b3324851336
- Benchmark: https://stackoverflow.com/questions/11406410/measure-time-in-ruby
- Ruby Style Guide: https://github.com/airbnb/ruby
- Markdown Guides
	- https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#code
	- https://guides.github.com/features/mastering-markdown/

## Steps to get on Bitshares (No Longer Used)

1. Setup your own Testnet Delayed Node
2. Testnet Bitshares Watcher (staggered orders that will be collected from your uploads)
3. Implement Gateway functionalities (On-Off ramp to BitShares)
4. Once you connect on-off to the issuer of dummy cloudcoin, script can handle transfers internally your BTS testnet account is issuing tokens/transfer to users on BTS testnet doing upload of CloudCoins through your app - real cloudcoins

So, on one side - BTS testnet delayed node and watcher + script
on other side - Ropsten Testnet ETH node + watcher + script

**Library:** [link](https://github.com/TrustyFund/vuex-bitshares "https://github.com/TrustyFund/vuex-bitshares")


## Staging Server

Get a VPS from Digital Ocean with the config: 8 GB Memory / 160 GB Disk / Debian 8.10 x64

- Multi-threading through Boost library for witness_node
- witness_node keeps one thread for consensus only

Create a 50 GB Swap File:
```bash
fallocate -l 50G /swapfile
```

Verify that the correct amount of space was reserved:
```bash
ls -lh /swapfile
```

Make the file only accessible to root:
```bash
chmod 600 /swapfile
```

Verify the permissions change:
```bash
ls -lh /swapfile
```

Mark the file as swap space:
```bash
mkswap /swapfile
```

Enable the swap file, allowing our system to start utilizing it:
```bash
swapon /swapfile
```

Verify that the swap is available:
```bash
swapon --show
```
and
```bash
free -h
```

Install software
```bash
sudo apt-get update && sudo apt-get install gcc-4.9 g++-4.9 cmake make \
                     libbz2-dev libdb++-dev libdb-dev \
                     libssl-dev openssl libreadline-dev \
                     autoconf libtool git libcurl4-openssl-dev \
                     autotools-dev build-essential \
                     g++ libbz2-dev libicu-dev python-dev screen -y
```

Running Witness Node using screen
```bash
/bitshares/bitshares-core/programs/witness_node:$ screen -dmS cctestnet ./witness_node

$ screen -r cctestnet
```

## References
- https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04