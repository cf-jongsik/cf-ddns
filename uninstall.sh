#! /bin/bash

if [ "$EUID" -ne 0 ]
then
  exec sudo $0 $@
fi

rm -rf /var/run/log/cf-ddns
rm -rf /usr/local/share/cf-ddns
rm -rf /etc/systemd/system/cf-ddns.service
rm -rf /etc/systemd/system/cf-ddns.timer
systemctl daemon-reload
