#! /bin/bash

if [ "$EUID" -ne 0 ]
then
  exec sudo $0 $@
fi

INSTALL_PATH="/usr/local/share/cf-ddns"
LOG_PATH="/var/log/cf-ddns"
DAEMON_PATH="/etc/systemd/system"

rm -rf "$LOG_PATH"
rm -rf "$INSTALL_PATH"
rm -rf "$DAEMON_PATH/cf-ddns.service"
rm -rf "$DAEMON_PATH/cf-ddns.timer"
systemctl daemon-reload
