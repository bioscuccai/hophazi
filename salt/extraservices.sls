{% if pillar.get("wants_vsftpd", False) %}
vsftpd:
  pkg:
    - installed

/etc/modules:
  file.append:
    - text: ip_conntrack_ftp
{% endif %}

{% if pillar.get("wants_sshd", False) %}
openssh-server:
  pkg:
    - installed
{% endif %}

/etc/network/iptables.up.rules:
  file.managed:
    - source: salt://iptables.up.rules.template
    - template: jinja
    - defaults:
        nginx_port: {{ pillar["nginx_port"] }}
        wants_ping: {{pillar.get("wants_ping", False)}}
        wants_vsftpd: {{pillar.get("wants_vsftpd", False)}}
        wants_sshd: {{pillar.get("wants_sshd", False)}}
        