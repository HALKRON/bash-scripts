#!/bin/bash

cd "$HOME" || exit

echo -e "\nPrinting the current user"
whoami && id

echo -e "\nMore details"
finger "$(whoami)"

echo -e "\nShowing passwd content of the user"
grep "$(whoami)" /etc/passwd

echo -e "\nShowing the groups the user $(whoami) belongs to"
grep "$(whoami)" /etc/group

echo -e "\nChecking user's expiration details"
chage -l "$(whoami)"
