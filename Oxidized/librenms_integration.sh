#! /bin/bash

if [ "$(whoami)" != "root" ]; then
        echo "Script must be run as root user"
        exit 255
fi

sudo -u librenms bash << EOF
lnms config:set oxidized.enabled true
lnms config:set oxidized.url http://127.0.0.1:8888
lnms config:set oxidized.features.versioning true
lnms config:set oxidized.group_support true
lnms config:set oxidized.reload_nodes true

EOF
