FROM quay.io/ansible/awx-ee:latest
ARG CURL_VERSION="7.86.0"
USER 0
RUN dnf install wget gcc make openssl openssl-devel libpq-devel python38-devel procps iputils diffutils -y && \
  wget https://curl.se/download/curl-${CURL_VERSION}.tar.gz && \
  tar xf curl-${CURL_VERSION}.tar.gz && \
  cd curl-${CURL_VERSION} && \
  ./configure --with-ssl && \
  make && \
  make install && \
  cd .. && \
  rm -rf curl-${CURL_VERSION} && \
  rm curl-${CURL_VERSION}.tar.gz
RUN curl -sS https://packages.microsoft.com/config/rhel/8/prod.repo | tee /etc/yum.repos.d/microsoft.repo && \
  dnf install --assumeyes powershell jq && \
  /usr/bin/python3 -m pip install --upgrade pip && \
  pip install --root-user-action=ignore wheel && \
  pip install --root-user-action=ignore pywinrm && \
  pip install --root-user-action=ignore pywinrm[credssp] && \
  pip install --root-user-action=ignore jmespath && \
  pip install --root-user-action=ignore psycopg2 && \
  chown -R 1000:1000 /home/runner/
USER 1000
RUN pip install hvac && \
    ansible-galaxy install 'git+https://github.com/TerryHowe/ansible-modules-hashivault.git' -p ~/.ansible/roles && \
    mkdir -p ~/.ansible/plugins/modules && \
    mkdir -p ~/.ansible/plugins/module_utils && \
    ln -s ~/.ansible/roles/ansible-modules-hashivault/ansible/modules/hashivault/ ~/.ansible/plugins/modules/hashivault && \
    ln ~/.ansible/roles/ansible-modules-hashivault/ansible/module_utils/hashivault.py ~/.ansible/plugins/module_utils/hashivault.py && \
    ansible-galaxy collection install cloud.common && \
    ansible-galaxy collection install community.kubernetes && \
    ansible-galaxy collection install community.windows && \
    ansible-galaxy collection install community.postgresql && \
    ansible-galaxy collection install f5networks.f5\_modules && \
    ansible-galaxy role install andrewrothstein.restic && \
    ansible-galaxy role install andrewrothstein.kubernetes-helm && \
    ansible-galaxy collection install community.vmware && \
    ansible-galaxy role install andrewrothstein.docker-compose && \
    ansible-galaxy collection install community.general
RUN pwsh -c '& {Install-Module -Name VMware.PowerCLI -Force -Scope CurrentUser -AllowClobber; \
  $conf = Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false; \
  $conf = Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false; \
  $conf = Set-PowerCLIConfiguration -DefaultVIServerMode 'Single' -Confirm:$false; \
  }'
