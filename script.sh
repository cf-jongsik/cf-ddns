#! /bin/bash
if [[ -s ./.env ]]
then
  echo "using .env file"
  source ./.env
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

curl -s https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" > records
cat records | jq '.result[] | select(.type=="A") | "\(.id),\(.name),\(.content)"' | tr -d \" > trim
IP=$(curl -s https://ifconfig.me)

if [[ -z $IP ]]
then
  echo "cannot get IP"
  exit -2
fi

echo "current ip : $IP"

if [[ ! -z $RECORD ]]
then
  echo "searching: $RECORD"
  ID=$(grep "$RECORD" trim | cut -d',' -f 1)
  if [[ ! -z $ID ]]
  then
    echo "found $ID"
    PRE_IP=$(grep "$RECORD" trim | cut -d',' -f 3)
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
  curl -s -X POST https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" > create
  cat create
}

update(){
  echo "update"
  IP=$(curl -s https://ifconfig.me)
  echo "id: $ID"
  DATA_STR="{\"content\":\"$IP\",\"name\":\"$RECORD\",\"type\":\"A\",\"proxied\":true,\"id\":\"$ID\"}"
  echo "data: $DATA_STR"
  curl -s -X PATCH https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"ID" --header "Authorization: Bearer $TOKEN" --data "$DATA_STR" > update
  cat update
}

delete(){
  echo "delete"
  curl -s -X DELETE https://api.cloudflare.com/client/v4/zones/"$ZONE"/dns_records/"$ID" --header "Authorization: Bearer $TOKEN" > delete
  cat delete
}


if [[ ! -z $ID ]]
then
  delete
fi
create
echo "done"
