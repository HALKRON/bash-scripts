#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

INSTALL_DIR=$(pwd)

mysql -u root librenms < "${INSTALL_DIR}"/files/alt_datetime.sql

cp -f /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

chmod 0775 /opt/librenms/rrd

# Setting Devices to be display by sysName then IP if the former is not available
# Setting Discovery by IP so that non-domain devices can be added automatically
# Enable Two Factor Authentication

sudo -u librenms bash << EOF
cd /opt/librenms
lnms config:set device_display_default '{{ $sysName_fallback }}'
lnms config:set webui.graph_type png
lnms config:set twofactor true
lnms config:set webui.dynamic_graphs true
lnms config:set discovery_by_ip true
EOF
