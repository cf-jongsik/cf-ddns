#! /bin/bash

if [ "$EUID" -ne 0 ]
then
  exec sudo $0 $@
fi

CURLPATH=$(type -p curl)
JQPATH=$(type -p jq)

if [[ ! -x "$JQPATH" || ! -x "$CURLPATH" ]]
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

if [[ -e /usr/local/cf-ddns || -s /etc/systemd/system/cf-ddns.service  || -s /etc/systemd/system/cf-ddns.timer ]]
then
  echo "previous installation found at /usr/local/cf-ddns"
  while [[ "${overwriteanswer^^}" != "Y" && "${overwriteanswer^^}" != "N" ]]
  do
    read -p "do you want to overwrite? (y/N) : " overwriteanswer
  done

  if [[ "${overwriteanswer^^}" == "N" ]]
  then
    echo "exiting"
    exit 0
  else
    while [[ "${envanswer^^}" != "Y" && "${envanswer^^}" != "N" ]]
    do
      read -p "do you want to keep the .env? (Y/n) : " envanswer
    done
  fi
fi

echo "recreating cf-ddns service"
rm -rf /etc/systemd/system/cf-ddns.service
rm -rf /etc/systemd/system/cf-ddns.timer
systemctl daemon-reload
cp "$PWD/cf-ddns.service" "/etc/systemd/system/"
cp "$PWD/cf-ddns.timer" "/etc/systemd/system/"
echo "done"

if [[ "${envanswer^^}" == "Y" ]]
then
  cp "/usr/local/share/cf-ddns/.env" "$PWD/.env.bak"
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

echo "recreating /usr/local/share/cf-ddns"
rm -rf /usr/local/share/cf-ddns
mkdir -p /usr/local/share/cf-ddns
cp "$PWD/.env.bak" "/usr/local/share/cf-ddns/.env"
cp "$PWD/script.sh" "/usr/local/share/cf-ddns/script.sh"
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