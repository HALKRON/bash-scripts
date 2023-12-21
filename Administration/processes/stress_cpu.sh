#!/bin/bash

VAR=${1:-3}

for ((i=1; i <= VAR; i++))
do
    cat /dev/zero > /dev/null &
done

pgrep -u klk -f "cat /dev/zero"

pgrep -u klk -f "cat /dev/zero" | while IFS= read -r process
do
    echo "Killing process ${process}..."
    kill "$process"
done

echo -e "\nProcesses after killing"
pgrep -u klk -f "cat /dev/zero"