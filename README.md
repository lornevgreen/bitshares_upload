# README

## TODO

## VERSIONS
- ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]
- Rails 5.2.0

## SYSTEM DEPENDENCIES

## CONFIGURATION

## LINKS

## DATABASE CREATION
- 

## DEPLOYMENT INSTRUCTIONS
https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/nginx/oss/deploy_updates.html

## REFERENCES
- https://ruby-doc.org/stdlib-2.5.1/libdoc/net/http/rdoc/Net/HTTP.html
- Markdown Guides
	- https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet#code
	- https://guides.github.com/features/mastering-markdown/

# STEPS TO GET ON BITSHARES

1. Setup your own Testnet Delayed Node
2. Testnet Bitshares Watcher (staggered orders that will be collected from your uploads)
3. Implement Gateway functionalities (On-Off ramp to BitShares)
4. Once you connect on-off to the issuer of dummy cloudcoin, script can handle transfers internally your BTS testnet account is issuing tokens/transfer to users on BTS testnet doing upload of CloudCoins through your app - real cloudcoins

So, on one side - BTS testnet delayed node and watcher + script
on other side - Ropsten Testnet ETH node + watcher + script

**Library:** [link](https://github.com/TrustyFund/vuex-bitshares "https://github.com/TrustyFund/vuex-bitshares")


# STAGING SERVER

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

## REFERENCES
- https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04
