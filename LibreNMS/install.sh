#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

# Initial Installations
printf "\n***Initial Installations***\n"

Installing PHP dependencies
apt update && apt full-upgrade -y

apt install software-properties-common
add-apt-repository universe
apt update
apt install acl curl composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-json php7.4-mbstring php7.4-mysql php7.4-snmp php7.4-xml php7.4-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools python3-systemd python3-pip

# Adding librenms user
printf "\n***Adding librenms user***\n"

useradd librenms -d /opt/librenms -M -r -s "$(which bash)"

# Installing LibreNMS
printf "\n***Installing LibreNMS***\n"

cd /opt || exit
git clone https://github.com/librenms/librenms.git

chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

# Installing PHP dependencies
printf "\n***Installing PHP dependencies***\n"

sudo -u librenms bash << EOF
./scripts/composer_wrapper.php install --no-dev
sleep 10
exit
EOF

# Configuring Timezone
printf "\n***Configuring Timzone***\n"

read -p "Enter your Region (eg. Asia, America, Africa): " -r REGION
read -p "Enter your Timezone (eg. London, Yangon, New_York): " -r TIMEZONE

if ! grep ^date.timezone /etc/php/7.4/fpm/php.ini ; then
    sed -i "s/\[Date\]/\[Date\]\ndate.timezone = ${REGION}\/${TIMEZONE}/g" /etc/php/7.4/fpm/php.ini
else
    sed -i "s/date.timezone.*/date.timezone = ${REGION}\/${TIMEZONE}/g" /etc/php/7.4/fpm/php.ini
fi

if ! grep ^date.timezone /etc/php/7.4/cli/php.ini ; then
    sed -i "s/\[Date\]/\[Date\]\ndate.timezone = ${REGION}\/${TIMEZONE}/g" /etc/php/7.4/cli/php.ini
else
    sed -i "s/date.timezone.*/date.timezone = ${REGION}\/${TIMEZONE}/g" /etc/php/7.4/cli/php.ini
fi

timedatectl set-timezone "${REGION}"/"${TIMEZONE}"

# Configuring MariaDB
printf "\n***Configuring MariaDB***\n"

sed -i "s/\[mysqld\]/\[mysqld\]\ninnodb_file_per_table=1\nlower_case_table_names=0/g" /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl enable mariadb
systemctl restart mariadb

read -p "Enter you database password: " -r DB_PASSWORD

mysql -u root <<MYSQL_INPUT
CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'librenms'@'localhost' IDENTIFIED BY "${DB_PASSWORD}";
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
FLUSH PRIVILEGES;
exit
MYSQL_INPUT

# Configuring PHP
printf "\n***Configuring PHP***\n"

cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/\[www\]/\[librenms\]/g" /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/^user.*/user = librenms/g" /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i "s/^group.*/group = librenms/g" /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/^listen.*/listen = /run/php-fpm-librenms.sock/g" /etc/php/7.4/fpm/pool.d/librenms.conf

# Configuring Web Server
printf "\n***Configuring Web Server***\n"

echo ""

INET=$((ip a || ifconfig) | grep inet | grep -n inet)

echo "$INET"

echo ""

while true; do
    read -p "Choose the network interface you want the webserver to open: " -r LINE_NUMBER
    if [[ $LINE_NUMBER -ge $(echo "$INET" | head -n 1 | awk -F: '{print $1}') && $LINE_NUMBER -le $(echo "$INET" | tail -n 1 | awk -F: '{print $1}') ]] ; then
        exit
    else
        printf "\nPlease choose between $(echo "$INET" | head -n 1 | awk -F: '{print $1}') - $(echo "$INET" | tail -n 1 | awk -F: '{print $1}')\n$INET\n"
    fi
done

INET=$(echo "$INET" | grep ^8 |  awk '{print $3}' | awk -F/ '{print $1}')

sed -i "s/server_name.*/server_name ${INET}/g" /etc/nginx/conf.d/librenms.conf

rm /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl restart php7.4-fpm

ln -s /opt/librenms/lnms /usr/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

# Configuring SNMP
printf "\n***Configuring SNMP***\n"

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

read -p "Enter your community string: " -r YOUR_SNMP_COMMUNTIY

sed -i "s/RANDOMSTRINGGOESHERE/${YOUR_SNMP_COMMUNITY}/g" /etc/snmp/snmpd.conf

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable snmpd
systemctl restart snmpd

cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

chown librenms:librenms /opt/librenms/config.php
