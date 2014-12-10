{% set rvm_user=pillar["rvm_user"] %}
{% set redmine_dir=pillar["redmine_dir"] %}
{% set redmine_db_name_prod=pillar["redmine_db_name_prod"] %}
{% set redmine_db_name_dev=pillar["redmine_db_name_dev"] %}
{% set redmine_db_user=pillar["redmine_db_user"] %}
{% set redmine_db_pw=pillar["redmine_db_pw"] %}

{% set puma_user=pillar["puma_user"] %}

{% set redmine_port=pillar["redmine_port"] %}
{% set redmine_url=pillar["redmine_url"] %}
{% set redmine_name=pillar["redmine_name"] %}
{% set nginx_port=pillar["nginx_port"] %}

req_packages:
  pkg.installed:
    - pkgs:
      - build-essential
      - ruby
      - ruby-dev
      - gcc
      - g++
      - htop
      - mc
      - curl
      - nginx
      - imagemagick
      - libmagickwand-dev
      - openssl
      - libssl-dev
      - mysql-server
      - mysql-common
      - mysql-client
      - libmysqlclient-dev
      - subversion
      - python-mysqldb

{{rvm_user}}:
  group:
    - present
  user.present:
    - gid: {{rvm_user}}
    - home: /home/{{rvm_user}}
    - require:
      - group: {{rvm_user}}

rvm_installer:
  cmd.script:
    - source: salt://rvm_install.sh
    - user: {{rvm_user}}
    - unless: test -s "/home/{{rvm_user}}/.rvm/scripts/rvm"
    - cwd: /home/

/home/{{rvm_user}}/.bashrc:
  file.append:
    - text: source ~/.rvm/scripts/rvm

http://svn.redmine.org/redmine/branches/2.6-stable:
  svn.latest:
    - target: {{redmine_dir}}
    - user: {{rvm_user}}

/etc/nginx/sites-enabled/default:
  file.absent

{{redmine_dir}}/Gemfile:
  file.append:
    - text:
      - 'gem "puma"'

{{redmine_dir}}/tmp/puma:
  file.directory:
    - user: {{rvm_user}}
    - group: {{rvm_user}}

{{redmine_dir}}/config/database.yml:
  file.managed:
    - source: salt://database.yml_template
    - template: jinja
    - defaults:
        redmine_db_name_dev: {{redmine_db_name_dev}}
        redmine_db_name_prod: {{redmine_db_name_prod}}
        redmine_db_user: {{redmine_db_user}}
        redmine_db_pw: {{redmine_db_pw}}

{{redmine_dir}}/config/puma.rb:
  file.managed:
    - source: salt://puma.rb_template
    - template: jinja
    - defaults:
        redmine_port: {{redmine_port}}
        redmine_dir: {{redmine_dir}}

##########################################
redmine_db_user:
  mysql_user.present:
    - name: {{redmine_db_user}}
    - host: localhost
    - password: {{redmine_db_pw}}

redmine_db_dev:
  mysql_database.present:
    - name: {{redmine_db_name_dev}}

redmine_db_prod:
  mysql_database.present:
    - name: {{redmine_db_name_prod}}

{{redmine_db_user}}_grant_{{redmine_db_name_dev}}:
  mysql_grants.present:
    - grant: all privileges
    - database: {{redmine_db_name_dev}}.*
    - user: {{redmine_db_user}}

{{redmine_db_user}}_grant_{{redmine_db_name_prod}}:
  mysql_grants.present:
    - grant: all privileges
    - database: {{redmine_db_name_prod}}.*
    - user: {{redmine_db_user}}
##########################################

redmine_bundle_rake:
  cmd.script:
    - source: salt://rvm_bundle.sh
    - user: {{rvm_user}}
    - cwd: {{redmine_dir}}

/etc/puma.conf:
  file.append:
    - text: {{redmine_dir}}

/etc/nginx/sites-available/{{redmine_name}}:
  file.managed:
    - source: salt://nginx_redmine.conf
    - template: jinja
    - defaults:
        redmine_name: {{redmine_name}}
        redmine_port: {{redmine_port}}
        redmine_dir: {{redmine_dir}}
        redmine_url: {{redmine_url}}
        nginx_port: {{nginx_port}}

/etc/nginx/sites-enabled/{{redmine_name}}:
  file.symlink:
    - target: /etc/nginx/sites-available/{{redmine_name}}

    
/etc/init/puma.conf:
  file.managed:
    - source: salt://puma.conf_template
    - template: jinja
    - defaults:
        rvm_user: {{rvm_user}}

/etc/init/puma-manager.conf:
  file.managed:
    - source: salt://puma-manager.conf_template
