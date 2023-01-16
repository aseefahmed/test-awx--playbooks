#!/bin/bash
set -e
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc

./mc alias set minio-do/ https://{{ minio_sub_domain }}.barfoot.co.nz {{ minio_admin_access_key }} "{{ minio_admin_secret_key }}"
./mc admin policy add minio-do minio-serverinfo $SCRIPT_DIR/minio-serverinfo.json

{% if minio_cluster_mode is not defined %}
./mc admin policy add minio-do minio-developers $SCRIPT_DIR/minio-developers.json
./mc admin policy set minio-do consoleAdmin group='{{ ldap_consoleAdmin }}'
./mc admin policy set minio-do minio-developers group='{{ ldap_minio_developers }}'
./mc admin policy set minio-do minio-serverinfo user='{{ ldap_minio_serverinfo }}'
./mc admin policy set minio-do readwrite user='{{ ldap_readwrite }}'
./mc admin user svcacct add --access-key "vercheck" --secret-key "{{ vercheck_secret_key }}" minio-do "svc-vercheck"
./mc admin user svcacct add --access-key "minio-db" --secret-key "{{ minio_db_secret_key }}" minio-do "svc-d-minio-db"
{% endif %}
{% if minio_cluster_mode is defined %}
./mc admin policy add minio-do ansiblerw $SCRIPT_DIR/ansiblerw.json
./mc admin policy add minio-do vagrant-boxesrw $SCRIPT_DIR/vagrant-boxesrw.json
./mc admin policy add minio-do vm-backupsrw $SCRIPT_DIR/vm-backupsrw.json
./mc admin policy add minio-do minio-teamcity $SCRIPT_DIR/minio-teamcity.json
./mc admin policy add minio-do installsrw $SCRIPT_DIR/installsrw.json
./mc admin user add minio-do ansible "{{ ansible_secret_key }}"
./mc admin user add minio-do packer "{{ packer_secret_key }}"
./mc admin user add minio-do vm-backups-awx "{{ vm_backups_awx_secret_key }}"
./mc admin policy set minio-do ansiblerw,installsrw user=ansible
./mc admin policy set minio-do vagrant-boxesrw user=packer
./mc admin policy set minio-do vm-backupsrw user=vm-backups-awx
./mc admin user add minio-do vercheck "{{ vercheck_secret_key }}"
./mc admin policy set minio-do minio-serverinfo user=vercheck
./mc admin user add minio-do teamcity "{{ teamcity_secret_key }}"
./mc admin policy set minio-do minio-teamcity user=teamcity
{% endif %}  
./mc alias remove minio-do
