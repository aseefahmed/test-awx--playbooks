#!/bin/bash
cat > /etc/cron.d/cert-copy << EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root HOME=/root
{{ cert_rotate_schedule }} root bash /root/manifests_rendered/cron-cert-copy.sh >> /root/cron-cert-copy.log 2>&1
EOF
