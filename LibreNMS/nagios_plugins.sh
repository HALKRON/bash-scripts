#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

sudo apt install monitoring-plugins nagios-plugins-contrib -y

sudo -u librenms bash << EOF
cd /opt/librenms
lnms config:set show_services 1
lnms config:set nagios_plugins /usr/lib/nagios/plugins
EOF

chmod +x /usr/lib/nagios/plugins/*

echo "*/5 * * * * librenms /opt/librenms/services-wrapper.py 1" | sudo tee --append /etc/cron.d/librenms
