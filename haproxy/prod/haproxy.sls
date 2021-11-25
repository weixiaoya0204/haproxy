http-isntall:
  pkg.installed:
    - pkgs:
      - make
      - gcc
      - pcre-devel
      - bzip2-devel
      - openssl-devel
      - systemd-devel

haproxy:
  user.present:
    - system: true
    - createhome: false
    - shell: /sbin/nologin

tar-haproxy:
  archive.extracted:
    - source: salt://modules/balancing/files/haproxy-{{ pillar ['haproxy-version'] }}.tar.gz
    - name: {{ pillar['haproxy_ins'] }}


install-haproxy:
  cmd.script:
    - name: salt://modules/balancing/files/install.sh.j2
    - template: jinja
    - require:
      - archive: tar-haproxy
    - unless:  test $(ls -d {{ pillar['haproxy_ins'] }}/haproxy)

/usr/bin/haproxy:
  file.symlink:
    - target: {{ pillar['haproxy_ins'] }}/sbin/haproxy

net.ipv4.ip_nonlocal_bind:
  sysctl.present:
    - value: 1

net.ipv4.ip_forward:
  sysctl.present:
    - value: 1

{{ pillar['haproxy_ins'] }}/haproxy/conf:
  file.directory:
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: true

copy-haproxy:
  file.managed:
    - source: salt://modules/balancing/files/haproxy.cfg.j2
    - name: {{ pillar['haproxy_ins'] }}/haproxy/conf/haproxy.cfg
    - template: jinja

copy-service:
  file.managed:
    - source: salt://modules/balancing/files/haproxy.service.j2
    - name: /usr/lib/systemd/system/haproxy.service
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja

copu-rsyslog.conf:
  file.managed:
    - name: /etc/rsyslog.conf
    - source: salt://modules/balancing/files/rsyslog.conf

haproxy-service:
  service.running:
    - name: haproxy.service
    - enable: true
    - reuqire:
      - file: copy-service
    - watch:
      - file: copy-haproxy

stop-rsylog.service:
  service.dead:
    - name: rsyslog.service

start-rsylog.service:
  service.running:
    - name: rsyslog.service
