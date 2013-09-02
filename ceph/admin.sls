{% macro hostlist(pattern) -%}
{%- for host in salt['mine.get'](pattern,'test.ping') %}{{ host }} {% endfor -%}
{%- endmacro %}

{% macro firsthost(pattern) -%} {{salt['mine.get'](pattern,'test.ping').keys()[0]}} {%- endmacro %}

include: 
  - ceph

ceph_create_cluster:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: ceph-deploy new  {{ hostlist('cephmon*') }}
    - unless: test -f ceph.conf

{% for host in salt['mine.get']('cephmon*','test.ping') %}
ceph_deploy_mon_{{host}}:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: ceph-deploy mon create {{host}}
    - unless: ssh {{host}} 'test -f /etc/ceph/ceph.conf'
    - require: 
      - cmd: ceph_create_cluster
{% endfor %}

ceph_gather_keys:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: sleep 30; ceph-deploy gatherkeys {{ firsthost('cephmon*') }} || ceph-deploy gatherkeys {{ salt['mine.get']('cephmon*','test.ping').keys()[1] }}  
    - require:
      {%- for host in salt['mine.get']('cephmon*','test.ping') %}
        - cmd: ceph_deploy_mon_{{host}}
      {%- endfor %}
    - unless: test -f ceph.client.admin.keyring && test -f ceph.mon.keyring && test -f ceph.bootstrap-osd.keyring && test -f ceph.bootstrap-mds.keyring

{% for host in salt['mine.get']('cephstorage*','test.ping') %}
ceph_prepare_osd_{{host}}:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: ceph-deploy osd prepare {{ host }}:/srv/osd 
    - require:
      - cmd: ceph_gather_keys
    - unless: ssh {{host}} 'test -f /srv/osd/fsid' 
{% endfor %}  

{% for host in salt['mine.get']('cephstorage*','test.ping') %}
ceph_activate_osd_{{host}}:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: while ! ceph -k ceph.client.admin.keyring osd tree |grep -q {{host}}; do ceph-deploy osd activate {{ host }}:/srv/osd; sleep 5; done
    - require:
      {%- for host in salt['mine.get']('cephstorage*','test.ping') %}
        - cmd: ceph_prepare_osd_{{host}}
      {%- endfor %}
    - unless: ceph -k /home/ceph/ceph.client.admin.keyring osd tree |grep {{ host }}
{% endfor %}  

ceph_add_mds:
  cmd.run:
    - user: ceph
    - cwd: /home/ceph
    - name: ceph-deploy mds create {{ firsthost('cephmon*') }}
    - require:
      {%- for host in salt['mine.get']('cephstorage*','test.ping') %}
      - cmd: ceph_activate_osd_{{host}}
      {%- endfor %}
    - unless: ceph -k ceph.client.admin.keyring status |grep "mdsmap.*up:active"
