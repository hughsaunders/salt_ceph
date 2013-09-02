ntp:
  pkg:
    - installed
  service:
    - running
    - watch:
      - file: /etc/ntp.conf

/etc/ntp.conf:
  file.managed:
    - source: salt://ntp/ntp.conf
    - require:
      - pkg: ntp
