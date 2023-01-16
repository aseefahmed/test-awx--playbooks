# ntp and hypervisor time sync enabled together cause boot time to drift and issues with prometheus metrics
# https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/1531
# https://github.com/prometheus/client_golang/issues/289
sudo vmware-toolbox-cmd timesync disable
