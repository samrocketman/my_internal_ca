#!/bin/bash
cd /root/my_internal_ca
./revoke_cert.sh homeassistant
./lan_server.sh homeassistant
cp -af myCA/private/homeassistant.key /etc/nginx/certs/homeassistant.key
cp -af myCA/certs/homeassistant.crt  /etc/nginx/certs/homeassistant.crt
systemctl reload nginx
