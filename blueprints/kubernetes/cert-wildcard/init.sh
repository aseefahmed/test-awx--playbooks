#!/bin/bash

cp /home/awx/.ssh/authorized_keys /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/authorized_keys
