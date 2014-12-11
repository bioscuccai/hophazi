install_backup:
  cmd.script:
    - source: salt://install_backup.sh
    - user: {{pillar["rvm_user"]}}
    - creates: ~/.backup_gem_installed

/home/{{pillar["rvm_user"]}}/Backup/models/my_backup.rb:
  file.managed:
    - source: salt://my_backup.rb.template
    - user: {{pillar["rvm_user"]}}
    - template: jinja
    - defaults:
        redmine_db_name_prod: {{pillar["redmine_db_name_prod"]}}
        redmine_db_user: {{pillar["redmine_db_user"]}}
        redmine_db_pw: {{pillar["redmine_db_pw"]}}

/etc/cron.allow:
  file.append:
    - text: {{pillar["rvm_user"]}}

/home/{{pillar["rvm_user"]}}/run_backup.sh:
  file.managed:
    - source: salt://run_backup.sh
    - user: {{pillar["rvm_user"]}}
    - mode: 777
  cron.present:
    - user: {{pillar["rvm_user"]}}
    - minute: '*/{{pillar["backup_interval"]}}'
