#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

mysql -u root <<MYSQL_INPUT
USE librenms;
ALTER TABLE notifications CHANGE datetime datetime timestamp NOT NULL DEFAULT '1970-01-02 00:00:00';
ALTER TABLE users CHANGE created_at created_at timestamp NOT NULL DEFAULT '1970-01-02 00:00:01';
exit
MYSQL_INPUT

cp -f /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms
