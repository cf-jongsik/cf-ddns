FROM ubuntu:latest
RUN apt-get update && apt-get install curl -y
RUN apt-get install jq cronie -y --no-install-recommends
RUN rm -rf /var/lib/apt/lists/*
COPY ./script.sh /root/
RUN chmod 0744 /root/script.sh
COPY ./crontab /etc/cron.d/cf-ddns
RUN chmod 0644 /etc/cron.d/cf-ddns
RUN crontab /etc/cron.d/cf-ddns
COPY ./entry.sh /root/entry.sh
RUN chmod 0744 /root/entry.sh
ENTRYPOINT ["/root/entry.sh"]
