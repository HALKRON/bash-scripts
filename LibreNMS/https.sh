#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
openssl dhparam -out /etc/nginx/dhparam.pem 4096

touch /etc/nginx/snippets/self-signed.conf
touch /etc/nginx/snippets/ssl-params.conf

cat <<EOT >> /etc/nginx/snippets/self-signed.conf
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOT

SERVER_NAME=$(grep server_name /etc/nginx/conf.d/librenms.conf)

read -p "Enter your DNS servers with space between them: " -r DNS_SERVERS

cp -f "${INSTALL_DIR}"/files/ssl-params.conf /etc/nginx/snippets/ssl-params.conf
cp -f "${INSTALL_DIR}"/files/librenms_https.conf /etc/nginx/conf.d/librenms.conf

sed -i "s/.*server_name.*/${SERVER_NAME}/g" /etc/nginx/conf.d/librenms.conf
sed -i "s/DNS/${DNS_SERVERS}/g" /etc/nginx/snippets/ssl-params.conf

systemctl restart nginx
