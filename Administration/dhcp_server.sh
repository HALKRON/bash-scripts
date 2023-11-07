#!/bin/bash

# Using dnsmasq for DHCP server

sudo apt update && sudo apt install dnsmasq

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.0

sudo cp files/dnsmasq.conf /etc/dnsmasq

sudo systemctl enable --now dnsmasq.service || sudo systemctl restart dnsmasq.service