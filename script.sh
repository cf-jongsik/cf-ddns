#! /bin/bash

INSTALL_PATH="/usr/local/share/cf-ddns"
LOG_PATH="/var/log/cf-ddns"

if [[ -s "$INSTALL_PATH/.env" ]]
then
  echo "using .env file"
  source "$INSTALL_PATH/.env"
fi

if [[ -z $ZONE || -z $TOKEN ]]
then
  echo "missing ZONE or TOKEN"
  rm -rf "$LOG_PATH" #remove for security
  exit -1
fi

CURL_PATH=$(type -p curl)
JQ_PATH=$(type -p jq)

if [[ ! -x "$CURL_PATH" && ! -s "$CURL_PATH" ]]
then
  echo "require curl package"
  rm -rf "$LOG_PATH" #remove for security
  exit -10
fi

if [[ ! -x "$JQ_PATH" && ! -s "$JQ_PATH" ]]
then
  echo "require jq package"
  rm -rf "$LOG_PATH" #remove for security
  exit -20
fi

rm -rf "$LOG_PATH"
mkdir -p "$LOG_PATH"

curl -s https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" > "$LOG_PATH/records"
if [[ -z "$LOG_PATH/records" ]]
then
  echo "invalid ZONE or TOKEN"
  rm -rf "$LOG_PATH" #remove for security
  exit -2
fi

cat "$LOG_PATH/records" | jq '.result[] | select(.type=="A") | "\(.id),\(.name),\(.content)"' | tr -d \" > "$LOG_PATH/trim"
IP=$(curl -s http://ifconfig.me)

if [[ -z $IP ]]
then
  echo "cannot get IP"
  rm -rf "$LOG_PATH" #remove for security
  exit -3
fi

echo "current ip : $IP"

if [[ ! -z $RECORD ]]
then
  echo "searching: $RECORD"
  ID=$(grep ",$RECORD\." "$LOG_PATH/trim" | cut -d',' -f 1)
  if [[ ! -z $ID ]]
  then
    echo "found $ID"
    PRE_IP=$(grep "$RECORD" "$LOG_PATH/trim" | cut -d',' -f 3)
    echo "previous IP: $PRE_IP"
    if [[ $PRE_IP == $IP ]]
    then
      echo "no need to update"
      rm -rf "$LOG_PATH" #remove for security
      exit 0
    else
      echo "need update"
    fi
  else
    echo "$RECORD not found"
  fi
else
  echo "missing RECORD"
  rm -rf "$LOG_PATH" #remove for security
  exit -4
fi

create(){
  echo "create"
  DATA_STR="{\"content\":\"$IP\",\"name\":\"$RECORD\",\"type\":\"A\",\"proxied\":true}"
  echo "data: $DATA_STR"
  curl -s -X POST https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" > "$LOG_PATH/create"
  cat "$LOG_PATH/create"
}

update(){
  echo "update"
  IP=$(curl -s https://ifconfig.me)
  echo "id: $ID"
  DATA_STR="{\"content\":\"$IP\",\"name\":\"$RECORD\",\"type\":\"A\",\"proxied\":true,\"id\":\"$ID\"}"
  echo "data: $DATA_STR"
  curl -s -X PATCH https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"ID" --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" > "$LOG_PATH/update"
  cat "$LOG_PATH/update"
}

delete(){
  echo "delete"
  curl -s -X DELETE https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"$ID" --header "Authorization: Bearer $TOKEN" > "$LOG_PATH/delete"
  cat "$LOG_PATH/delete"
}

if [[ ! -z $ID ]]
then
  delete
fi
create
rm -rf "$LOG_PATH" #remove for security
echo ""
