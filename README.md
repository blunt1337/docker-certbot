# Certbot for Nginx

A simple and light docker image to create/renew SSL certificates with letsencrypt.

# Howto

Following sample is for nginx, but you can use it with apache too. Just change the proxy configuration.

First you need to forward certbot's request to our certbot container:
```
# Letsencrypt
location ^~ /.well-known/acme-challenge/ {
	proxy_pass http://certbot:80;
}
```
Host and port are to change accordingly to your configuration. I recommand using docker-compose to have the hostname mapping.

Then you need to add an ssl configuration and the volume ./ssl bind to /etc/nginx/ssl/
```
listen 443 ssl;
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;
```

To finish, you need to have a running certbot container:  
`docker run -d -e "DOMAIN=blunt.sh" -e "EMAIL=contact@blunt.sh" -v ./ssl:/result/ssl -e "RELOAD_CMD=???" -n certbot blunt1337/certbot`  

The reload command depends on your configuration, it is run every time the ssl certificate is modified.  
Our container as docker installed in it, so if you want to execute commands on another container, you can by adding `-v /var/run/docker.sock:/var/run/docker.sock:ro`  
For example: `docker exec sample_web_1 /bin/sh -c 'kill -SIGHUP $(cat /var/run/nginx.pid)'`  
(don't forget to escape $ with \ when passing the command inside -e "RELOAD_CMD=\$escaped", and with $$ in compose.yml)

# You can checkout the sample docker-compose

Change the domain name 'home.blunt.sh' inside nginx.conf and docker-compose.yml, then run it with docker-compose up
