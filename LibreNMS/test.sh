#! /bin/bash

INET=$((ip a || ifconfig) | grep inet | grep -n inet)

echo "$INET"

echo ""

while true; do
    read -p "Choose the network interface you want the webserver to open: " -r LINE_NUMBER
    if [[ $LINE_NUMBER -ge $(echo "$INET" | head -n 1 | awk -F: '{print $1}') && $LINE_NUMBER -le $(echo "$INET" | tail -n 1 | awk -F: '{print $1}') ]] ; then
        INET=$(echo "$INET" | grep ^$LINE_NUMBER |  awk '{print $3}' | awk -F/ '{print $1}')
        break
    else
        printf "\nPlease choose between $(echo "$INET" | head -n 1 | awk -F: '{print $1}') - $(echo "$INET" | tail -n 1 | awk -F: '{print $1}')\n$INET\n"
    fi
done

echo "$INET"
