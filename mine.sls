salt-minion:
  service:
    - running
    - enable: True

/etc/salt/minion:
  file:
    - append
    - text: |
        mine_functions:
          network.interfaces: []
          test.ping: []
          grains.items: []
