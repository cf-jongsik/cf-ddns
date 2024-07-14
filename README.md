<p><h1>Cloudflare DNS update agent</h1></p>

<p>

This docker image create and update A record of Cloudflare DNS <br/>

and let you use Cloudflare as dynamic DNS service.

</p>

<p>
<h1>#INSTALLATION</h1>
<h3>##OPTION 1 - docker compose</h3>

<h6>1. Edit the following sample then save as docker-compose.yaml <br/></h6>

```dockerfile
services:
  cf-ddns:
    image: docker.io/neomax7/cf-ddns:latest
    environment:
    - TOKEN=PLACE_YOUR_OWN_TOKEN # your TOKEN from Cloudflare Dashboard (require ZONE edit)
    - ZONE=PLACE_YOUR_OWN_ZONE # your ZONE ID from Cloudflare Dashboard
    - RECORD=PLACE_YOUR_SUBDOMAIN # Subdomain of your choice , example: test.example.com => example.com = zone , test = subdomain
    #- TIMEZONE=PLACE_YOUR_TIMEZONE # OPTIONAL: for more accurate cronjob otherwise its UTC
    #- CRON=* * * * * # OPTIONAL: default is every 5 min, make sure no quote or double quote
```

<br/>

<h6>2. in the same directory as above file</h6>

```bash
docker compose up -d
```

</p>
<br/>
<p>
<h3>##OPTION 2 - docker</h3>

```bash
docker run -d --rm --env TOKEN=YOUR_TOKEN --env ZONE=YOUR_ZONE_ID --env RECORD=RECORD_OF_CHOICE neomax7/cf-ddns:latest
```

</p>

<br/>

<p>
<h1>#Environment Variables</h1>
This agent takes following environment variables<br/>

```bash
#required
TOKEN = Cloudflare API TOKEN with DNS EDIT permission
ZONE = ZONE ID from Cloudflare dashboard
RECORD = name of A record wish to register
#optional
CRON = typical cron schedule ex: */5 * * * *
TIMEZONE = your timezone
```

</p>
<br/>
<p>
<h1>#DESCRIPTION</h1>

script content <br />

1. \$CRON schedule fires the script <br />
2. the script searches for the \$RECORD in your \$ZONE <br />
3. if the \$RECORD exists, delete the record <br />
   (currently Cloudflare API doenst let you patch or put with Bearer token) <br />
4. create the \$RECORD with public IP from ifconfig.me <br />

</p>
