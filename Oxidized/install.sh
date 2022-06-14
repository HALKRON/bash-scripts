#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

add-apt-repository universe
apt update && apt full-upgrade -y
apt install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev libicu-dev zlib1g-dev g++ -y

gem install oxidized
gem install oxidized-script oxidized-web

useradd -s /bin/bash -m -d /opt/oxidized oxidized

read -p "Enter LibreNMS Server Address: " -r LIBRE_NMS
read -p "Enter LibreNMS Token: " -r LIBRE_TOKEN

#Copy from files to config

sudo -u librenms bash << EOF
oxidized
cp -f $INSTALL_DIR/files/oxidized_config $HOME/
EOF

# add service

