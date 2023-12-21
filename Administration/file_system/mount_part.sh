#!/bin/bash

findmnt -S LABEL="Windows" > /dev/null
IF_MOUNTED=$?

if [[ $IF_MOUNTED == 1 ]]
then
    sudo mount -L "Windows" --target ~/part1 -o ro
    echo "Mounted"
elif [[ $IF_MOUNTED == 0 ]]
then
    sudo umount ~/part1
    echo "Unmounted"
fi
