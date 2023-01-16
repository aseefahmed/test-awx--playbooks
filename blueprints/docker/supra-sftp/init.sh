#!/bin/bash

pass={{ stg_pass }}
stg_pass=$(perl -e 'print crypt($ARGV[0], "password")' $pass)
sudo useradd -m -p $stg_pass -u 2000 -U stg-supra
mkdir -p /home/stg-supra/sftp
chown 2000:2000 /home/stg-supra/sftp

pass={{ test_pass }}
test_pass=$(perl -e 'print crypt($ARGV[0], "password")' $pass)
sudo useradd -m -p $test_pass -u 2001 -U test-supra
mkdir -p /home/test-supra/sftp
chown 2001:2001 /home/test-supra/sftp
