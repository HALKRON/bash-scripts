#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

LIBRENMS_HOME_DIR=/opt/librenms

read -p "Do you wish to change the LibreNMS Dir? ($LIBRENMS_HOME_DIR) " -r LIBRENMS_HOME_DIR

cat "$INSTALL_DIR"/files/nagios_config.php >> "$LIBRE_HOME_DIR"/config.php
