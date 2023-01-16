#!/bin/bash

cat > /etc/cron.d/rotate-certs << EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root HOME=/root
{{ cert_rotate_schedule }} root bash /root/rotate-certs.sh >> /root/rotate-certs.log 2>&1
EOF
