#! /bin/bash

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

sudo apt install ./wkhtmltox_0.12.6-1.focal_amd64.deb

sudo rm -f ./wkhtmltox_0.12.6-1.focal_amd64.deb -y

sudo -u odoo15 bash << EOF
git clone https://www.github.com/odoo/odoo --depth 1 --branch 15.0 /opt/odoo15/odoo
cd /opt/odoo15
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip3 install wheel
pip3 install -r odoo/requirements.txt
cd /opt/odoo15/odoo
./odoo-bin
sleep 30
deactivate
mkdir /opt/odoo15/odoo-custom-addons
exit
EOF

odoo_conf=/etc/odoo15.conf

read -p "Choose your admin password to the database: " -r admin_passwd
read -p "Choose the database you wish to connect to: " -r database_name

sudo mv files/odoo15.conf $odoo_conf

sudo sed "s/password/${admin_passwd}/g" -i $odoo_conf
sudo sed "s/database_name/${database_name}/g" -i $odoo_conf

sudo mv files/odoo15.service /etc/systemd/system/odoo15.service

sudo systemctl daemon-reload

sudo systemctl enable --now odoo15
sudo systemctl status odoo15

sleep 10

sudo apt install nginx
sudo systemctl status nginx

sleep 10

sudo apt install certbot
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp www-data /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt

sudo mv files/letsencrypt.conf /etc/nginx/snippets/letsencrypt.conf

read -p "Enter your website domain: " -r website_domain
read -p "Do you have www as subdomain for this? (Y/N)[N] " -r www_website

case $www_website in
    Yes|yes|Y|y )
        www_website=true;
    ;;
    * )
        www_website=false;
    ;;
esac

sudo mkdir -p /etc/nginx/sites-available/ && sudo cp -f ./files/sites-avail-1 /etc/nginx/sites-available/"${website_domain}"

if [[ $www_website == false ]] ; then
    sudo sed "s/ www.YOURWEBSITE.COM//g;s/YOURWEBSITE.COM/${website_domain}/g" -i /etc/nginx/sites-available/"$website_domain"
else
    sudo sed "s/YOURWEBSITE.COM/${website_domain}/g" -i /etc/nginx/sites-available/"$website_domain"
fi

sudo ln -s /etc/nginx/sites-available/"${website_domain}" /etc/nginx/sites-enabled/

sudo systemctl restart nginx

read -p "Enter your email" -r email

if $www_website ; then
    sudo certbot certonly --agree-tos --email "$email" --webroot -w /var/lib/letsencrypt/ -d "$website_domain" -d "$website_domain"
else
    sudo certbot certonly --agree-tos --email "$email" --webroot -w /var/lib/letsencrypt/ -d "$website_domain"
fi

echo ' --renew-hook "systemctl reload nginx"' | sudo tee -a /etc/cron.d/certbot

if $www_website ; then
    sudo cp -f ./files/sites-avail-2-www.conf /etc/nginx/sites-available/"${website_domain}" && sudo sed "s/YOURWEBSITE.COM/${website_domain}/g" -i /etc/nginx/sites-available/"${website_domain}"
else
    sudo cp -f ./files/sites-avail-2.conf /etc/nginx/sites-available/"${website_domain}" && sudo sed "s/YOURWEBSITE.COM/${website_domain}/g" -i /etc/nginx/sites-available/"${website_domain}"
fi

sudo systemctl restart nginx

echo "" >> /etc/odoo15.conf
echo "proxy_mode = True"

sudo systemctl restart odoo15
