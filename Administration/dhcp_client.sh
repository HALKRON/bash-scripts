#!/bin/bash

sudo dhclient -r
sudo dhclient

echo -e "\nShow current dhcp leases"
cat /var/lib/dhcp/dhclient.leases
