#!/bin/bash

# Using dnsmasq for DHCP server

if [[ $(whoami) != "root" ]]; then
    printf "Run this script as root!\n"
    exit
fi

ip -bri a
read -p "What interface would you like to configure? " -r INTERFACE

apt update && sudo apt install dnsmasq

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.0

cp ../files/dnsmasq.conf /etc/dnsmasq

sed -i "s/ensXX/$INTERFACE/g" /etc/dnsmasq.conf

systemctl enable --now dnsmasq.service ; systemctl restart dnsmasq.service