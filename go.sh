#!/usr/bin/env bash
main(){
  set -x
  mine_data=(network.interfaces test.ping grains.items)
  salt-cloud -d -m ceph.map -y          # delete current instances
  sleep 60
  salt-key -D                           # delete keys for current instances
  salt-cloud -y -m ceph.map -P          # create new set of instances
  for item in ${mine_data[@]}           # Populate salt mine
  do
    salt '*' mine.send "$item" 
  done
  salt-run state.over                   # run states in the order specified in overstate.sls
}

time main
