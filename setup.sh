#!/bin/bash
set -e

# Packages
apk upgrade -q -U -a
apk add --update openssl
apk add --update certbot
apk add --update docker

# Pathes
mkdir -p /result/ssl

# Default ssl self-signed
mkdir -p /etc/letsencrypt/selfsigned
openssl req -new -newkey rsa:2048 -days 1 -nodes -x509 \
	-subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=sample.com" \
	-keyout /etc/letsencrypt/selfsigned/privkey.pem \
	-out /etc/letsencrypt/selfsigned/fullchain.pem

# Main script
echo "#!/bin/sh
exec 2>&1

# Check envs
if [ -z \"\$EMAIL\" ]; then
	echo \"Missing email environement variable\" >&2
	exit 1
fi
if [ -z \"\$DOMAIN\" ]; then
	echo \"Missing domain environement variable\" >&2
	exit 1
fi

# Default ssl self-signed
if [ ! -f /result/ssl/privkey.pem ] || [ ! -f /result/ssl/fullchain.pem ]; then
	cp /etc/letsencrypt/selfsigned/privkey.pem /result/ssl/privkey.pem
	cp /etc/letsencrypt/selfsigned/fullchain.pem /result/ssl/fullchain.pem
fi

# Wait 30sec for nginx to start
sleep 30s

while true; do
	# Generate / renew
	certbot certonly --standalone --preferred-challenges http -m \"\$EMAIL\" -d \"\$DOMAIN\" --cert-name default -n --agree-tos --keep
	
	# Old cert md5
	sum=\$(md5sum /result/ssl/fullchain.pem)
	
	# Replace self signed / old files if needed
	if [ \"\$sum\" != \"\$(md5sum /etc/letsencrypt/live/default/fullchain.pem)\" ]; then
		cp -Lfu /etc/letsencrypt/live/default/fullchain.pem /result/ssl/fullchain.pem
		cp -Lfu /etc/letsencrypt/live/default/privkey.pem /result/ssl/privkey.pem
		
		# Reload nginx config
		/bin/sh -c \"\$RELOAD_CMD\"
	fi
	
	# Wait to renew
	sleep 1d
done" > /bootstrap.sh
chmod +x /bootstrap.sh

# Clean
rm -rf /tmp/*
rm -rf /var/cache/apk/*
rm -r "$0"