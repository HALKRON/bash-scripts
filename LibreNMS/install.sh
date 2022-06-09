#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

apt update && apt full-upgrade -y

apt install software-properties-common
add-apt-repository universe
apt update
apt install acl curl composer fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php7.4-cli php7.4-curl php7.4-fpm php7.4-gd php7.4-gmp php7.4-json php7.4-mbstring php7.4-mysql php7.4-snmp php7.4-xml php7.4-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools python3-systemd python3-pip

useradd librenms -d /opt/librenms -M -r -s "$(which bash)"

cd /opt || exit
git clone https://github.com/librenms/librenms.git

chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

sudo -u librenms bash << EOF
./scripts/composer_wrapper.php install --no-dev
exit
EOF

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

cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/\[www\]/\[librenms\]/g" /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/^user.*/user = librenms/g" /etc/php/7.4/fpm/pool.d/librenms.conf
sed -i "s/^group.*/group = librenms/g" /etc/php/7.4/fpm/pool.d/librenms.conf

sed -i "s/^listen.*/listen = /run/php-fpm-librenms.sock/g" /etc/php/7.4/fpm/pool.d/librenms.conf

echo ""

INET=$((ip a || ifconfig) | grep inet | grep -n inet)

echo "$INET"

echo ""

while true; do
    read -p "Choose the network interface you want the webserver to open: " -r LINE_NUMBER
    case $LINE_NUMBER in
        [[$(echo "$INET" | head -n 1 | cut -c 1)-$(echo "$INET" | tail -n 1 | cut -c 1)]] ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
