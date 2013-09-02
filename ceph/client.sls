include: 
  - ceph

rbd:
  kmod.present:
    - require:
      - pkg: linux-image-extra-{{ grains['kernelrelease'] }}

create rbd:
  cmd.run:
    - name: rbd create test_rbd --size 4096 -k ceph.client.admin.keyring
    - user: ceph
    - cwd: /home/ceph
    - unless: rbd -k ceph.client.admin.keyring list |grep -q test_rbd
    - require: 
      - kmod: rbd

map rbd:
  cmd.run:
    - name: sudo rbd map test_rbd --pool rbd --name client.admin -k ceph.client.admin.keyring
    - user: ceph
    - cwd: /home/ceph
    - unless: test -e /dev/rbd/rbd/test_rbd
    - require: 
      - cmd: create rbd

make fs on rbd:
  cmd.run:
    - name: mkfs.ext4 /dev/rbd/rbd/test_rbd
    - unless: mount |grep -q test_rbd || ( mount /dev/rbd/rbd/test_rbd /mnt/test_rbd && umount /mnt/test_rbd ) 
    - require: 
      - cmd: map rbd

/mnt/test_rbd:
  mount.mounted:
    - device: /dev/rbd/rbd/test_rbd
    - fstype: ext4
    - mkmnt: True
    - require:
      - cmd: make fs on rbd
    - unless: mount |grep -q /mnt/test_rbd


