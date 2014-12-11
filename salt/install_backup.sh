#!/bin/bash
source ~/.rvm/scripts/rvm
gem install backup --no-ri --no-rdoc
backup generate:model --trigger my_backup --archives --storages='local' --compressor='gzip' --databases="mysql"
