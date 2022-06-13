#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

mysql -u root librenms < "${INSTALL_DIR}"/files/alt_datetime.sql

cp -f /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms
