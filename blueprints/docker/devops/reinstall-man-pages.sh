#!/bin/bash

set -eax

export DEBIAN_FRONTEND=noninteractive
xargs -rd '\n' -a <(debsums -c 2>&1 | cut -d " " -f 4 | sort -u | xargs -rd '\n' -- dpkg -S | cut -d : -f 1 | sort -u) -- apt-get install -yf --reinstall --
