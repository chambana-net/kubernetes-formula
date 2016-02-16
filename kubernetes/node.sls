{% from "kubernetes/map.jinja" import kubernetes with context %}
{% set settings = salt['pillar.get']('kubernetes:lookup:settings', {}) %}

kube_node_group:
  group.present:
    - name: kube
    - system: True

kube_node_user:
  user.present:
    - name: kube
    - fullname: Kubernetes User
    - system: True
    - gid_from_name: True
    - home: {{ kubernetes.prefix }}
    - require:
      - group: kube_node_group

kubelet:
  file.managed:
    - name: {{ kubernetes.prefix }}/sbin/kubelet
    - source: salt://kubernetes/vendor/kubelet
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kubelet_config:
  file.managed:
    - name: {{ kubernetes.config_dir }}/kubelet.conf
    - source: salt://kubernetes/files/config/kubelet.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        hostname_override: {{ settings.get('hostname_override', '') }}
        api_servers: {{ settings.get('api_servers', 'http://127.0.0.1:8080') }}
        cluster_dns: {{ settings.get('cluster_dns', '') }}
        cluster_domain: {{ settings.get('cluster_domain', '') }}
        config: {{ settings.get('config', '') }}
        other_opts: {{ settings.get('otther_opts', '') }}

kubelet_service:
  file.managed:
    - name: /etc/systemd/system/kubelet.service
    - source: salt://kubernetes/files/systemd/kubelet.service
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: kubelet
    - enable: True
    - require:
      - file: kubelet_service
      - file: kubelet_config
      - file: kubelet
      - user: kube_node_user
      - group: kube_node_group

kube-proxy:
  file.managed:
    - name: {{ kubernetes.prefix }}/sbin/kube-proxy
    - source: salt://kubernetes/vendor/kube-proxy
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kube-proxy_config:
  file.managed:
    - name: {{ kubernetes.config_dir }}/kube-proxy.conf
    - source: salt://kubernetes/files/config/kube-proxy.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        hostname_override: {{ settings.get('hostname_override', '') }}
        master: {{ settings.get('master', 'http://127.0.0.1:8080') }}
        other_opts: {{ settings.get('other_opts', '') }}

kube-proxy_service:
  file.managed:
    - name: /etc/systemd/system/kube-proxy.service
    - source: salt://kubernetes/files/systemd/kube-proxy.service
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: kube-proxy
    - enable: True
    - require:
      - file: kube-proxy_service
      - file: kube-proxy_config
      - file: kube-proxy
      - user: kube_node_user
      - group: kube_node_group
