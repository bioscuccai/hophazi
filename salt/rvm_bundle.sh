#!/bin/bash
source ~/.rvm/scripts/rvm
bundle install
rake db:create db:migrate
RAILS_ENV=production rake db:create db:migrate
rake generate_secret_token
