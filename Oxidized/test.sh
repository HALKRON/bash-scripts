#! /bin/bash

while true; do
    read -p "Is your server SSL encrypted?[Yes/No] " -r HTTPS
    if [[ $HTTPS =~ ^[Yy]es$ ]] ; then
        HTTPS=true
        break
    elif [[ $HTTPS =~ ^[nN]o$ ]] ; then
        HTTPS=false
        break
    else
        echo "Yes or No only!"
    fi
done

echo $HTTPS

if [[ $HTTPS == true ]] ; then
        sed "s/url: http/url: https/g" files/oxidized_config
fi
