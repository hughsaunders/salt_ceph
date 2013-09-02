all:
  match: '*'
  sls:
    - ssh
    - hosts
    - ntp
    - mine

ceph_base:
  match: 'ceph*'
  sls:
      - ceph

ceph_admin:
  match: 'cephadmin'
  sls:
    - ceph.admin
  require:
    - ceph_base
    - ceph_storage

ceph_client:
  match: 'cephadmin'
  sls:
    - ceph.client
  require:
    - ceph_admin

ceph_storage:
  match: 'cephstorage*'
  sls:
    - ceph.storage_node
  require:
    - ceph_base
