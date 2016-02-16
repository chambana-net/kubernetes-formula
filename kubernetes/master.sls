{% from "kubernetes/map.jinja" import kubernetes with context %}
{% set settings = salt['pillar.get']('kubernetes:lookup:settings', {}) %}

kube_master_group:
  group.present:
    - name: kube
    - system: True

kube_master_user:
  user.present:
    - name: kube
    - fullname: Kubernetes User
    - system: True
    - gid_from_name: True
    - home: {{ kubernetes.prefix }}
    - require:
      - group: kube_master_group

kube-apiserver:
  file.managed:
    - name: {{ kubernetes.prefix }}/sbin/kube-apiserver
    - source: salt://kubernetes/vendor/kube-apiserver
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kube-apiserver_config:
  file.managed:
    - name: {{ kubernetes.config_dir }}/kube-apiserver.conf
    - source: salt://kubernetes/files/config/kube-apiserver.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        insecure_bind_address: {{ settings.get('insecure_bind_address', '0.0.0.0') }}
        insecure_port: {{ settings.get('insecure_port', '8080') }}
        etcd_servers: {{ settings.get('etcd_servers', 'http://127.0.0.1:4001') }}
        service_cluster_ip_range: {{ settings.get('service_cluster_ip_range', '') }}
        admission_control: {{ settings.get('admission_control', '') }}
        service_node_port_range: {{ settings.get('service_node_port_range', '') }}
        advertise_address: {{ settings.get('advertise_address', '' ) }}
        client_ca_file: {{ settings.get('client_ca_file', kubernetes.resource_dir ~ '/ca.crt') }}
        tls_cert_file: {{ settings.get('tls_cert_file', kubernetes.resource_dir ~ '/server.cert') }}
        tls_private_key_file: {{ settings.get('tls_private_key_file', kubernetes.resource_dir ~ '/server.key') }}
        other_opts: {{ settings.get('other_opts', '') }}

kube-apiserver_service:
  file.managed:
    - name: /etc/systemd/system/kube-apiserver.service
    - source: salt://kubernetes/files/systemd/kube-apiserver.service
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: kube-apiserver
    - enable: True
    - require:
      - file: kube-apiserver_service
      - file: kube-apiserver_config
      - file: kube-apiserver
      - user: kube_master_user
      - group: kube_master_group

kube-controller-manager:
  file.managed:
    - name: {{ kubernetes.prefix }}/sbin/kube-controller-manager
    - source: salt://kubernetes/vendor/kube-controller-manager
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kube-controller-manager_config:
  file.managed:
    - name: {{ kubernetes.config_dir }}/kube-controller-manager.conf
    - source: salt://kubernetes/files/config/kube-controller-manager.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        master: {{ settings.get('master', '127.0.0.1:8080') }}
        root_ca_file: {{ settings.get('root_ca_file', kubernetes.resource_dir ~ '/ca.crt') }}
        service_account_private_key_file: {{ settings.get('service_account_private_key_file', kubernetes.resource_dir ~ '/server.key') }}
        other_opts: {{ settings.get('other_opts', '') }}

kube-controller-manager_service:
  file.managed:
    - name: /etc/systemd/system/kube-controller-manager.service
    - source: salt://kubernetes/files/systemd/kube-controller-manager.service
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: kube-controller-manager
    - enable: True
    - require:
      - file: kube-controller-manager_service
      - file: kube-controller-manager_config
      - file: kube-controller-manager
      - user: kube_master_user
      - group: kube_master_group

kube-scheduler:
  file.managed:
    - name: {{ kubernetes.prefix }}/sbin/kube-scheduler
    - source: salt://kubernetes/vendor/kube-scheduler
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kube-scheduler_config:
  file.managed:
    - name: {{ kubernetes.config_dir }}/kube-scheduler.conf
    - source: salt://kubernetes/files/config/kube-scheduler.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - defaults:
        master: {{ settings.get('master', '127.0.0.1:8080') }}
        other_opts: {{ settings.get('other_opts', '') }}

kube-scheduler_service:
  file.managed:
    - name: /etc/systemd/system/kube-scheduler.service
    - source: salt://kubernetes/files/systemd/kube-scheduler.service
    - user: root
    - group: root
    - mode: 0644

  service.running:
    - name: kube-scheduler
    - enable: True
    - require:
      - file: kube-scheduler_service
      - file: kube-scheduler_config
      - file: kube-scheduler
      - user: kube_master_user
      - group: kube_master_group

kubectl:
  file.managed:
    - name: {{ kubernetes.prefix }}/bin/kubectl
    - source: salt://kubernetes/vendor/kubectl
    - user: root
    - group: root
    - mode: 0750
    - makedirs: True

kube_profile:
  file.managed:
    - name: /etc/profile.d/kubectl.sh
    - source: salt://kubernetes/files/kubectl.sh
    - user: root
    - group: root
    - mode: 0644
    - makedirs: True
    - require:
      - file: kubectl
