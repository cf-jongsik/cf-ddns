#! /bin/bash
printenv >> /etc/environment
if [[ ! -v ZONE || ! -v TOKEN || ! -v RECORD ]]
then
  echo "missing required env"
  exit -1
fi
if [[ -v TIMEZONE ]]
then
  echo "updating timezone: $TIMEZONE"
  echo $TIMEZONE > /etc/timezone
fi
if [[ -v CRON ]]
then
  echo "updating crontab: $CRON"
  echo "$CRON$(cat /etc/cron.d/cf-ddns | cut -d'*' -f 6)" > /etc/cron.d/new_cf-ddns
  cat /etc/cron.d/new_cf-ddns
  crontab /etc/cron.d/new_cf-ddns
fi
exec crond -f
