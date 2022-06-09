#! /bin/bash

while true; do
    read -p "Choose the network interface you want the webserver to open: " -r LINE_NUMBER
    case $LINE_NUMBER in
        [$(echo "$INET" | head -n 1 | cut -c 1)-$(echo "$INET" | tail -n 1 | cut -c 1)] ) make install; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
