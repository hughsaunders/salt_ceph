ceph:
  pkgrepo.managed:
    - humanname: cephrepo
    - key_url: 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
    - name: "deb http://ceph.com/debian-dumpling/ {{grains['lsb_distrib_codename']}} main"
  pkg.installed:
    - names:
      - ceph
      - ceph-deploy
      - linux-image-extra-{{ grains['kernelrelease'] }}
    - require: 
      - pkgrepo: ceph
    - refresh: true
  user:
    - present
    - shell: /bin/bash

ceph_user_skel:
  cmd:
    - run
    - name: cp /etc/skel/.* /home/ceph
    - unless: test -f /home/ceph/.bashrc
    - require: 
      - user: ceph

/home/ceph/.ssh:
  file:
    - directory
    - mode: 700
    - user: ceph
    - group: ceph
    - require:
      - user: ceph

/home/ceph/.ssh/id_rsa:
  file:
    - managed
    - source: salt://ceph/id_rsa.ceph
    - mode: 0600
    - user: ceph
    - group: ceph
    - require:
      - file: /home/ceph/.ssh
      - user: ceph

/home/ceph/.ssh/authorized_keys:
  file:
    - managed
    - source: salt://ceph/id_rsa.ceph.pub
    - user: ceph
    - group: ceph
    - require:
      - file: /home/ceph/.ssh
      - user: ceph

/etc/sudoers.d/ceph:
  file:
    - managed
    - user: root
    - group: root
    - mode: 0440
    - contents: "ceph ALL=(ALL) NOPASSWD:ALL\n"

/etc/ssh/ssh_config:
  file:
    - append
    - source: salt://ceph/ssh_config
