#!/bin/bash
cd ~
curl -sSL https://github.com/wayneeseguin/rvm/tarball/stable -o rvm-stable.tar.gz
mkdir rvm && cd rvm
tar --strip-components=1 -xzf ../rvm-stable.tar.gz
./install --auto-dotfiles
source ~/.rvm/scripts/rvm
rvm mount -r https://rvm_io.global.ssl.fastly.net/binaries/ubuntu/14.04/x86_64/ruby-2.1.5.tar.bz2 --verify-downloads 2
rvm use ruby-2.1.5 --default
rvm gemset create rm1
rvm use ruby-2.1.5@rm1 --default
