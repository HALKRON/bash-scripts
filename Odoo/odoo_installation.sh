#! /bin/bash

INSTALL_DIR=`pwd`

sudo apt update && sudo apt full-upgrade -y

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql

sudo apt install vim libpq-dev build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev -y

sudo pg_ctlcluster 12 main start

# Creates a system user named odoo15 who has the home directory of "/opt/odoo15" with its own user group as well.
sudo useradd -m -d /opt/odoo15 -U -r -s /bin/bash odoo15

# Creates a superuser for Postgresql
sudo su - postgres -c "createuser -s odoo15"

# Installs Wkhtmltopdf which converts HTML to PDF
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb

sudo apt install ./wkhtmltox_0.12.6-1.focal_amd64.deb -y

sudo rm -f ./wkhtmltox_0.12.6-1.focal_amd64.deb

sudo -u odoo15 bash << EOF
git clone https://www.github.com/odoo/odoo --depth 1 --branch 15.0 /opt/odoo15/odoo
cd /opt/odoo15
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip3 install wheel
pip3 install -r odoo/requirements.txt
deactivate
mkdir /opt/odoo15/odoo-custom-addons
exit
EOF

ODOO_CONF=/etc/odoo15.conf

read -p "Choose your admin password to the database: " -r ADMIN_PASSWD
read -p "Choose the database you wish to connect to: " -r DATABASE_NAME

sudo cp -f "${INSTALL_DIR}"/files/odoo15.conf $ODOO_CONF

sudo sed "s/password/${ADMIN_PASSWD}/g" -i $ODOO_CONF
sudo sed "s/DATABASE_NAME/${DATABASE_NAME}/g" -i $ODOO_CONF

sudo cp -f "${INSTALL_DIR}"/files/odoo15.service /etc/systemd/system/odoo15.service

sudo systemctl daemon-reload

sudo systemctl enable --now odoo15

sudo apt install nginx -y

sudo apt install certbot -y
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp www-data /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt

sudo cp -f "${INSTALL_DIR}"/files/letsencrypt.conf /etc/nginx/snippets/letsencrypt.conf

read -p "Enter your website domain: " -r WEBSITE_DOMAIN
read -p "Do you have www as subdomain for this? (Y/N)[N] " -r WWW_WEBSITE

case $WWW_WEBSITE in
    Yes|yes|Y|y )
        WWW_WEBSITE=true;
    ;;
    * )
        WWW_WEBSITE=false;
    ;;
esac

sudo mkdir -p /etc/nginx/sites-available/ && sudo cp -f "${INSTALL_DIR}"/files/sites-avail-1.conf /etc/nginx/sites-available/"${WEBSITE_DOMAIN}"

if [[ $WWW_WEBSITE == false ]] ; then
    sudo sed "s/ www.YOURWEBSITE.COM//g;s/YOURWEBSITE.COM/${WEBSITE_DOMAIN}/g" -i /etc/nginx/sites-available/"$WEBSITE_DOMAIN"
else
    sudo sed "s/YOURWEBSITE.COM/${WEBSITE_DOMAIN}/g" -i /etc/nginx/sites-available/"$WEBSITE_DOMAIN"
fi

sudo ln -s /etc/nginx/sites-available/"${WEBSITE_DOMAIN}" /etc/nginx/sites-enabled/

sudo systemctl restart nginx

read -p "Enter your email" -r YOUR_EMAIL

if $WWW_WEBSITE ; then
    sudo certbot certonly --agree-tos --email "$YOUR_EMAIL" --webroot -w /var/lib/letsencrypt/ -d "$WEBSITE_DOMAIN" -d "$WEBSITE_DOMAIN"
else
    sudo certbot certonly --agree-tos --email "$YOUR_EMAIL" --webroot -w /var/lib/letsencrypt/ -d "$WEBSITE_DOMAIN"
fi

echo ' --renew-hook "systemctl reload nginx"' | sudo tee -a /etc/cron.d/certbot

if $WWW_WEBSITE ; then
    sudo cp -f "${INSTALL_DIR}"/files/sites-avail-2-www.conf /etc/nginx/sites-available/"${WEBSITE_DOMAIN}" && sudo sed "s/YOURWEBSITE.COM/${WEBSITE_DOMAIN}/g" -i /etc/nginx/sites-available/"${WEBSITE_DOMAIN}"
else
    sudo cp -f "${INSTALL_DIR}"/files/sites-avail-2.conf /etc/nginx/sites-available/"${WEBSITE_DOMAIN}" && sudo sed "s/YOURWEBSITE.COM/${WEBSITE_DOMAIN}/g" -i /etc/nginx/sites-available/"${WEBSITE_DOMAIN}"
fi

sudo systemctl restart nginx

echo "" >> /etc/odoo15.conf
echo "proxy_mode = True"

sudo systemctl restart odoo15
