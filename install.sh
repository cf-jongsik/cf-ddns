#! /bin/bash

if [ "$EUID" -ne 0 ]
then
  exec sudo $0 $@
fi

INSTALL_PATH="/usr/local/share/cf-ddns"
LOG_PATH="/var/log/cf-ddns"
DAEMON_PATH="/etc/systemd/system"

CURL_PATH=$(type -p curl)
JQ_PATH=$(type -p jq)

if [[ ! -x "$JQ_PATH" || ! -x "$CURL_PATH" ]]
then
  echo "installing requirements : jq, curl"
  if [[ -x $(type -p apt) ]]
  then
    apt install jq curl -y
  elif [[ -x $(type -p dnf) ]]
  then
    dnf install jq curl -y
  fi
  echo "done"
fi

if [[ -e /usr/local/cf-ddns || -s "$DAEMON_PATH/cf-ddns.service"  || -s "$DAEMON_PATH/cf-ddns.timer" ]]
then
  echo "previous installation found at /usr/local/cf-ddns"
  while [[ "${OVERWRITE_ANSWER^^}" != "Y" && "${OVERWRITE_ANSWER^^}" != "N" ]]
  do
    read -p "do you want to overwrite? (y/N) : " OVERWRITE_ANSWER
    if [[ -z $OVERWRITE_ANSWER ]]
    then
      OVERWRITE_ANSWER="N"
    fi
  done

  if [[ "${OVERWRITE_ANSWER^^}" == "N" ]]
  then
    echo "exiting"
    exit 0
  else
    while [[ "${ENV_ANSWER^^}" != "Y" && "${ENV_ANSWER^^}" != "N" ]]
    do
      read -p "do you want to keep the .env? (Y/n) : " ENV_ANSWER
      if [[ -z $ENV_ANSWER ]]
      then
        ENV_ANSWER="Y"
      fi
    done
  fi
fi

echo "recreating cf-ddns service"
rm -rf "$DAEMON_PATH/cf-ddns.service"
rm -rf "$DAEMON_PATH/cf-ddns.timer"
systemctl daemon-reload
cp "$PWD/cf-ddns.service" "$DAEMON_PATH/"
cp "$PWD/cf-ddns.timer" "$DAEMON_PATH/"
echo "done"

if [[ "${ENV_ANSWER^^}" == "Y" ]]
then
  cp "$INSTALL_PATH/.env" "$PWD/.env.bak"
else
  read -p 'enter your cloudflare bearer token (zone edit permission) hidden: ' -s TOKEN
  echo ""
  read -p 'enter your zone id: (from cloudflare dashboard - zone - overview) ' ZONE
  read -p 'enter A record name of your choice: (ex:server1) ' RECORD
  echo "done"

  echo "TOKEN=$TOKEN" > .env.bak
  echo "ZONE=$ZONE" >> .env.bak
  echo "RECORD=$RECORD" >> .env.bak
fi

echo "recreating $INSTALL_PATH"
rm -rf $INSTALL_PATH
mkdir -p $INSTALL_PATH
cp "$PWD/.env.bak" "$INSTALL_PATH/.env"
cp "$PWD/script.sh" "$INSTALL_PATH/script.sh"
echo "done"

echo "registering service"
systemctl daemon-reload
echo "enabling timer"
systemctl enable --now cf-ddns.timer
systemctl status cf-ddns.timer
echo "registering"
systemctl start cf-ddns.service
systemctl status cf-ddns.service
echo "done"