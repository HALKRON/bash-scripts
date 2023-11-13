#!/bin/bash

sudo dhclient -r #Release the current lease and stop the running DHCP client
sudo dhclient #Renew DHCP

echo -e "\nShow current dhcp leases"
cat /var/lib/dhcp/dhclient.leases
