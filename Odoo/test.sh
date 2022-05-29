#! /bin/bash

read -p "Enter your website domain: " -r website_domain
read -p "Do you have www as subdomain for this? (Y/N)[N] " -r www_website

case $www_website in
    Yes|yes|Y|y )
        www_website=true;
    ;;
    * )
        www_website=false;
    ;;
esac

if $www_website ; then
    echo "True"
else
    echo "False"
fi
