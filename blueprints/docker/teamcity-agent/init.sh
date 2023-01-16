#!/bin/bash

sudo timedatectl set-timezone Pacific/Auckland
cat > /etc/cron.d/docker-prune << EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root HOME=/root
0 5 * * * root docker system prune -af --volumes >> /root/docker-prune.log 2>&1
EOF
