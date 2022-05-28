#! /bin/bash

sudo apt update && sudo apt full-upgrade -y

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql

sudo apt install libpq-dev build-essential python3-pillow python3-lxml python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev libxml2-dev python3-wheel python3-venv libxslt1-dev node-less libjpeg-dev -y

sudo pg_ctlcluster 12 main start

# Creates a system user named odoo15 who has the home directory of "/opt/odoo15" with its own user group as well.
sudo useradd -m -d /opt/odoo15 -U -r -s /bin/bash odoo15

# Creates a superuser for Postgresql
sudo su - postgres -c "createuser -s odoo15"

# Installs Wkhtmltopdf which converts HTML to PDF
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb

sudo apt install ./wkhtmltox_0.12.6-1.focal_amd64.deb

sudo rm -f ./wkhtmltox_0.12.6-1.focal_amd64.deb

sudo -u odoo15 bash << EOF
git clone https://www.github.com/odoo/odoo --depth 1 --branch 15.0 /opt/odoo15/odoo
cd /opt/odoo15
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip3 install wheel
pip3 install -r odoo/requirements.txt
cd /opt/odoo15/odoo
./odoo-bin
EOF
