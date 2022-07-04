#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

read -p "Enter LibreNMS Server Address: " -r LIBRE_NMS 

while true; do
    read -p "Is your server SSL encrypted? [Yes/No] " -r HTTPS
    if [[ $HTTPS =~ ^[Yy]es$ ]] ; then
        HTTPS=true
        break
    elif [[ $HTTPS =~ ^[nN]o$ ]] ; then
        HTTPS=false
        break
    else
        echo "Yes or No only!"
    fi
done

read -p "Enter Oxidized Username: " -r USERNAME
read -p "Enter Oxidized Password: " -r PASSWORD
read -p "Enter Git Email: " -r EMAIL
read -p "Enter LibreNMS Token: " -r LIBRE_TOKEN

INSTALL_DIR=$(pwd)
OXIDIZED_CONF=/opt/oxidized/.config/oxidized/config

add-apt-repository universe
apt update && apt full-upgrade -y
apt install ruby ruby-dev libsqlite3-dev libssl-dev pkg-config cmake libssh2-1-dev libicu-dev zlib1g-dev g++ -y

gem install oxidized
gem install oxidized-script oxidized-web

useradd -s /bin/bash -m -d /opt/oxidized oxidized

#Copy from files to config

sudo -u oxidized bash << EOF
oxidized
EOF

cp -f "$INSTALL_DIR"/files/oxidized_config $OXIDIZED_CONF
chown oxidized:oxidized $OXIDIZED_CONF

sed -i "s/USERNAME/$USERNAME/g" "$OXIDIZED_CONF"
sed -i "s/PASSWORD/$PASSWORD/g" "$OXIDIZED_CONF"
sed -i "s/EMAIL/$EMAIL/g" "$OXIDIZED_CONF"
sed -i "s/LIBRE_TOKEN/$LIBRE_TOKEN/g" "$OXIDIZED_CONF"
sed -i "s/LIBRE_NMS/$LIBRE_NMS/g" "$OXIDIZED_CONF"

if [[ $HTTPS == true ]] ; then
        sed -i "s/url: http/url: https/g" $OXIDIZED_CONF
fi

# Add service
cp -f "$INSTALL_DIR"/files/oxidized.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable oxidized.service
systemctl restart oxidized.service
