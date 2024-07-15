#! /bin/bash
if [[ -s /usr/local/share/cf-ddns/.env ]]
then
  echo "using .env file"
  source /usr/local/share/cf-ddns/.env
fi

if [[ -z $ZONE || -z $TOKEN ]]
then
  echo "no ZONE or TOKEN"
  exit -1
fi

CURL_PATH=$(type -p curl)

if [[ ! -x "$CURL_PATH" && ! -s "$CURL_PATH" ]]
then
  echo "require curl"
  exit -10
fi

rm -rf /var/run/log/cf-ddns
mkdir -p /var/run/log/cf-ddns/

curl -s https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" > /var/run/log/cf-ddns/records
cat /var/run/log/cf-ddns/records | jq '.result[] | select(.type=="A") | "\(.id),\(.name),\(.content)"' | tr -d \" > /var/run/log/cf-ddns/trim
IP=$(curl -s http://ifconfig.me)

if [[ -z $IP ]]
then
  echo "cannot get IP"
  exit -2
fi

echo "current ip : $IP"

if [[ ! -z $RECORD ]]
then
  echo "searching: $RECORD"
  ID=$(grep ",$RECORD\." /var/run/log/cf-ddns/trim | cut -d',' -f 1)
  if [[ ! -z $ID ]]
  then
    echo "found $ID"
    PRE_IP=$(grep "$RECORD" /var/run/log/cf-ddns/trim | cut -d',' -f 3)
    echo "previous IP: $PRE_IP"
    if [[ $PRE_IP == $IP ]]
    then
      echo "no need to update"
      exit 0
    else
      echo "need to update"
    fi
  else
    echo "nothing found"
  fi
else
  echo "missing RECORD"
  exit -3
fi

create(){
  echo "create"
  DATA_STR="{\"content\":\"$IP\",\"name\":\"$RECORD\",\"type\":\"A\",\"proxied\":true}"
  echo "data: $DATA_STR"
  curl -s -X POST https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" >/var/run/log/cf-ddns/create
  cat /var/run/log/cf-ddns/create
}

update(){
  echo "update"
  IP=$(curl -s https://ifconfig.me)
  echo "id: $ID"
  DATA_STR="{\"content\":\"$IP\",\"name\":\"$RECORD\",\"type\":\"A\",\"proxied\":true,\"id\":\"$ID\"}"
  echo "data: $DATA_STR"
  curl -s -X PATCH https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"ID" --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" > /var/run/log/cf-ddns/update
  cat /var/run/log/cf-ddns/update
}

delete(){
  echo "delete"
  curl -s -X DELETE https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"$ID" --header "Authorization: Bearer $TOKEN" > /var/run/log/cf-ddns/delete
  cat /var/run/log/cf-ddns/delete
}


if [[ ! -z $ID ]]
then
  delete
fi
create
echo ""
