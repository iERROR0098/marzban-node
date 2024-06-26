#!/bin/bash

# Update package lists and upgrade existing packages
apt-get update
apt-get install -y curl socat git wget unzip

# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone the Marzban-node repository
git clone https://github.com/Gozargah/Marzban-node

# Create directories
mkdir -p /var/lib/marzban-node
mkdir -p /var/lib/marzban/xray-core

# Navigate to the Marzban-node directory
cd ~/Marzban-node

# Remove existing docker-compose.yml
rm -f docker-compose.yml

# Create a new docker-compose.yml file
cat <<EOF >docker-compose.yml
services:
  marzban-node-1:
    image: gozargah/marzban-node:latest
    restart: always
    environment:
      SSL_CLIENT_CERT_FILE: "/var/lib/marzban-node/me.pem"
      XRAY_EXECUTABLE_PATH: "/var/lib/marzban/xray-core/xray"
    volumes:
      - /var/lib/marzban-node:/var/lib/marzban-node
      - /var/lib/marzban:/var/lib/marzban
    ports:
      - 1710:62050
      - 1711:62051
      - 6000:443
EOF

# Add placeholder certificate
echo "-----BEGIN CERTIFICATE-----
MIIEnDCCAoQCAQAwDQYJKoZIhvcNAQENBQAwEzERMA8GA1UEAwwIR296YXJnYWgw
IBcNMjMxMDMwMjM0OTUxWhgPMjEyMzEwMDYyMzQ5NTFaMBMxETAPBgNVBAMMCEdv
emFyZ2FoMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAzYFwQoSM+XCi
Y43AJGJ5bnLbKeDzp8qqAhGuHgAtC6jUzHnUwirKepnDSiAXmFhGrUBfgQ9ncr+0
t0+vPlC+pfTRH2QdDP/JmnHyx8wwzAwpRUS3bRe0g3d47cl8HGIcFtQsmCI1ayO/
ea8HFsk3ap34oxTBnoAZoDaF/JQgouKtQZsg5g6Inti5M2LWI6BIua1spjxkOjhF
5N+lP9NJw1/3LVrnR5PK8wlGy0slC7ZJ7CeXF8hPa80CnyhqvmCx1pdTW90XC30/
WU9E7ajh+iiG0tSepmY5pAXfwZzj69FOXfm3YEQm6vdQtrxgr2kt7iHoNlnrWYes
H2g7PLsysmYSRfzud7e3Ctc23k4eED+MEUBkQdrCnvy2LDCv8TORFrJ+bcocV3ZF
qXxhxwJf4l/ehgKMjJOho88PK5BcxdWc7rPymBbH/7u/cuGPJOS1ga/eE33XWVZ8
EbCoPaJUtvZCYAlzNkaotv4HJRh2qhdHqy/CIA6Rr3JUAhCjWEfcyRmuzm9vxpFn
C6UrsOmofcoi9oplUv8o6abj51bY3vrG0IFIJjFlUcsV+9343PCg6MMEWJhexoOB
IExXQlNO9ga2kElqSPjG+yq+5qZlU5P57WhopcpmlKg697pDPBp+vu26PvYzxKkA
Cc+f2Bz9IxWTU7pKylz2RXNKOzI2jM0CAwEAATANBgkqhkiG9w0BAQ0FAAOCAgEA
GMt7sNFZzDzeF6VvBWKIe/kgh15Pe89zXg6v7HZH2mgAP6CTbb4Zi8GkUJFwzIts
z1cUSXfOvtN0Nde0df2enh+De2I8rRFvxSkSSHhqIWR+JDgMMLhLjW3C2dpzojul
lORZGJ+fqCQMpRp77N06lPKa+fx9rAOjYB8z8BlM4U3La0Hrzw6YpCSPQrygmaKY
QsEHI559yldV9aoleZb3Tsi0YkRc3QDKPOIicFyqodi/eYxAxMtR8qyKnXn2Jfu2
jTvxMvHbD9kweMA1uWwwny0ERftx62tkOGKBniGz74CGVu3eEZSkIXxoivjBL1Jz
Aq9Gyhjnw34S48lVFi3dK8fbt82ntWXmQL3k5sJiA3q/u36raxQCIe7Wf7IJpDFv
DmWZyBUFsMi5ybW6xtO5MeN7qyN8PPXBY1uQT9S5yrZ/pYMLHBrWg/ob0U+RhLb0
/GVOx29YZ8gi8+6b/Jx1/huKciciU0qPff6G58wfOpnqdT5FjlzkPRfH3I1FqajC
J8U4jbh68KSWRD+O0hbqFbf+jeOLcV0OEDZyaq/yN+e9Lz3Xy7Ho8EsfVsJVQ5RO
Qnm6dQciw6WQHqdl+Y4t1p5yu3EQV9SAVYoEdzgImp6FH7om/WRhcxmDXCcNeI0O
/JUPbLUABoTXBoKDeLEAndtwYuonw1AVUMOlzQG9Juc=
-----END CERTIFICATE-----" > /var/lib/marzban-node/me.pem

# Download and extract Xray core
cd /var/lib/marzban/xray-core
wget https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip

# Start Marzban-node
cd ~/Marzban-node
docker compose down --remove-orphans
docker compose up -d

# Install HAProxy
apt-get install -y haproxy

# Configure HAProxy
cat <<EOF >> /etc/haproxy/haproxy.cfg

listen front
  mode tcp
  bind *:443
  tcp-request inspect-delay 5s
  tcp-request content accept if { req_ssl_hello_type 1 }
  use_backend reality if { req.ssl_sni -m end app.hubspot.com | www.sephora.com | cdn.discordapp.com | icloud.com }

backend reality
  mode tcp
  server sv1 127.0.0.1:6000 send-proxy

frontend http_front
  bind *:80
  mode http
  redirect location https://nextcloud.technologiewerk-qua.de code 301

backend http_back
  mode http
  balance roundrobin
EOF

# Restart HAProxy service
systemctl restart haproxy.service

# Print a success message
echo "Marzban-node, Xray core, and HAProxy setup completed!"
