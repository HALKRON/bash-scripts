#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

read -p "Enter you database password: " -r DB_PASSWORD
read -p "Enter your Region (eg. Asia, America, Africa): " -r REGION
read -p "Enter your Timezone (eg. London, Yangon, New_York): " -r TIMEZONE

echo ""

INET=$( (ip a || ifconfig) | grep inet | grep -n inet )

printf "\n%s\n\n" "$INET"

while true; do
    read -p "Choose the network interface you want the webserver to open: " -r LINE_NUMBER
    if [[ $LINE_NUMBER -ge $(echo "$INET" | head -n 1 | awk -F: '{print $1}') && $LINE_NUMBER -le $(echo "$INET" | tail -n 1 | awk -F: '{print $1}') ]] ; then
        INET=$(echo "$INET" | grep ^"$LINE_NUMBER" |  awk '{print $3}' | awk -F/ '{print $1}')
            break
    else
        printf "\nPlease choose between $(echo %s | head -n 1 | awk -F: '{print $1}') - $(echo %s | tail -n 1 | awk -F: '{print $1}')\n%s\n" "$INET"
    fi
done

# Initial Installations
printf "\n***Initial Installations***\n"

apt update && apt full-upgrade -y

apt install software-properties-common
add-apt-repository universe
apt update
apt install tzdata acl curl composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-json php7.4-mbstring php7.4-mysql php7.4-snmp php7.4-xml php7.4-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools python3-systemd python3-pip -y

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
/opt/librenms/scripts/composer_wrapper.php install --no-dev
sleep 10
exit
EOF

# Configuring MariaDB
printf "\n***Configuring MariaDB***\n"

sed -i "s/\[mysqld\]/\[mysqld\]\ninnodb_file_per_table=1\nlower_case_table_names=0/g" /etc/mysql/mariadb.conf.d/50-server.cnf

systemctl enable mariadb
systemctl restart mariadb

mysql -u root << MYSQL_INPUT
CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'librenms'@'localhost' IDENTIFIED BY "${DB_PASSWORD}";
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
FLUSH PRIVILEGES;
exit
MYSQL_INPUT

# Configuring Timezone
printf "\n***Configuring Timzone***\n"

if ! grep ^date.timezone /etc/php/7.4/fpm/php.ini ; then
    sed -i "s/\[Date\]/\[Date\]\ndate.timezone = \"${REGION}\/${TIMEZONE}\"/g" /etc/php/7.4/fpm/php.ini
else
    sed -i "s/date.timezone.*/date.timezone = \"${REGION}\/${TIMEZONE}\"/g" /etc/php/7.4/fpm/php.ini
fi

if ! grep ^date.timezone /etc/php/7.4/cli/php.ini ; then
    sed -i "s/\[Date\]/\[Date\]\ndate.timezone = \"${REGION}\/${TIMEZONE}\"/g" /etc/php/7.4/cli/php.ini
else
    sed -i "s/date.timezone.*/date.timezone = \"${REGION}\/${TIMEZONE}\"/g" /etc/php/7.4/cli/php.ini
fi

timedatectl set-timezone "${REGION}"/"${TIMEZONE}"

mysql_tzinfo_to_sql /usr/share/zoneinfo/ | sudo mysql -u root mysql
mysql -u root -e "SET GLOBAL time_zone='${REGION}/${TIMEZONE}';"

systemctl restart mariadb

# Configuring PHP
printf "\n***Configuring PHP***\n"

cp -f /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/\[www\]/\[librenms\]/g; s/^user.*/user = librenms/g; s/^group.*/group = librenms/g; s/^listen = .*/listen = \/run\/php-fpm-librenms.sock/g" /etc/php/7.4/fpm/pool.d/librenms.conf

# Configuring Web Server
printf "\n***Configuring Web Server***\n"

echo "Your web server will be available at $INET"
sleep 10

cp -f "${INSTALL_DIR}"/files/librenms.conf /etc/nginx/conf.d/librenms.conf

sed -i "s/SERVER_IP/${INET}/g" /etc/nginx/conf.d/librenms.conf

rm /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl restart php7.4-fpm

ln -s /opt/librenms/lnms /usr/bin/lnms
cp -f /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

# Configuring SNMP
printf "\n***Configuring SNMP***\n"

cp -f /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

read -p "Enter your community string: " -r YOUR_SNMP_COMMUNITY

sed -i "s/RANDOMSTRINGGOESHERE/${YOUR_SNMP_COMMUNITY}/g" /etc/snmp/snmpd.conf

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro
systemctl enable snmpd
systemctl restart snmpd

cp -f /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

sudo -u librenms bash << EOF
cd /opt/librenms
lnms config:set device_display_default '{{ $sysName_fallback }}'
lnms config:set webui.dynamic_graphs true
EOF
